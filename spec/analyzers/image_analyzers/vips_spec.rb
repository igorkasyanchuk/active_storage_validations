# frozen_string_literal: true

require "rails_helper"
require "analyzers/support/analyzer_helpers"

RSpec.describe ActiveStorageValidations::Analyzer::ImageAnalyzer::Vips, image_processor: :vips do
  def self.test_rotatable_media?
    true
  end

  let(:analyzer) { described_class.new(attachable) }

  # Using a jpg file to test rotation because the behaviour is uniform among OS,
  # we tried doing it with a png file but the result was different
  # between our local machine and the CI.
  let(:media_extension) { ".png" }
  let(:media_extension_rotated) { ".jpg" }
  let(:media_filename) { "image_150x150#{media_extension}" }
  let(:media_filename_over_10ko) { "image_150x150_28ko#{media_extension}" }
  let(:media_filename_rotated) { "image_700x500_rotated_90#{media_extension_rotated}" }
  let(:media_filename_0ko) { "image_file_0ko#{media_extension}" }
  let(:media_path) { Rails.root.join("public", media_filename) }
  let(:media_io) { open_fixture(media_path) }
  let(:media_content_type) { "image/png" }
  let(:media_content_type_rotated) { "image/jpeg" }
  let(:expected_metadata) { { width: 150, height: 150 } }
  let(:expected_metadata_over_10ko) { { width: 150, height: 150 } }
  let(:expected_metadata_rotated) { { width: 700, height: 500 } }

  it_behaves_like "returns the right metadata for any attachable"
  it_behaves_like "applies the exif orientation"
  it_behaves_like "reports the displayed image size"
  it_behaves_like "reads a bracketed path as itself"

  describe "multi-frame images" do
    subject(:metadata) { analyzer.metadata }

    let(:path) { Rails.root.join("public", "image_200x100_animated.gif").to_s }
    let(:attachable) do
      {
        io: open_fixture(path),
        filename: "image_200x100_animated.gif",
        content_type: "image/gif"
      }
    end

    it "returns the dimensions of the first frame" do
      expect(metadata).to eq({ width: 200, height: 100 })
    end
  end

  # Older Rails do not call Vips.block_untrusted(true): the analyzer skips the
  # unfuzzed loaders itself, unless the app turned the blocking on.
  describe "untrusted (unfuzzed) loaders" do
    subject(:metadata) { analyzer.metadata }

    let(:was_blocked) { {} }
    let(:app_reenables_svg) { false }

    before do
      require "vips"
      skip "requires libvips 8.13+ and ruby-vips 2.2.1+" unless ::Vips.respond_to?(:block_untrusted) && ::Vips.at_least_libvips?(8, 13)

      was_blocked[:value] = described_class.untrusted_operations_blocked?
      ::Vips.block_untrusted(app_blocks_untrusted)
      ::Vips.block("VipsForeignLoadSvg", false) if app_reenables_svg
    end

    after do
      ::Vips.block_untrusted(was_blocked[:value]) if was_blocked.key?(:value)
      ActiveStorageValidations::ProcessableFileValidator.reset_vips_untrusted_operations_blocked_cache!
    end


    context "when the app does not block them" do
      let(:app_blocks_untrusted) { false }

      context "with an SVG (svgload)" do
        let(:attachable) { svg_file }

        it { expect(metadata).to eq({}) }
      end

      context "with a PNG (pngload)" do
        let(:attachable) { png_file }

        it { expect(metadata).to eq({ width: 150, height: 150 }) }
      end
    end

    context "when the app blocks them but re-enables svgload" do
      let(:app_blocks_untrusted) { true }
      let(:app_reenables_svg) { true }
      let(:attachable) { svg_file }

      it { expect(metadata).to eq({ width: 150, height: 150 }) }
    end
  end

  describe "timeouts" do
    let(:path) { Rails.root.join("public", "image_150x150.png").to_s }
    let(:attachable) do
      {
        io: open_fixture(path),
        filename: "image_150x150.png",
        content_type: "image/png"
      }
    end
    let(:analyzer) { described_class.new(attachable, timeout: 0.1) }

    after { ActiveStorageValidations.command_timeout = 10.seconds }

    it "returns empty metadata and emits timeout when the load exceeds the deadline" do
      release = Queue.new
      events = []
      subscriber = ActiveSupport::Notifications.subscribe("timeout.active_storage_validations") do |*args|
        events << ActiveSupport::Notifications::Event.new(*args)
      end

      allow(analyzer).to receive(:open_vips_image) { release.pop; nil }
      expect(analyzer.metadata).to eq({})

      expect(events.size).to eq(1)
      expect(events.first.payload[:command]).to eq("vips")
      expect(events.first.payload[:timeout]).to be_within(0.001).of(0.1)
    ensure
      release << :done if defined?(release)
      ActiveSupport::Notifications.unsubscribe(subscriber) if defined?(subscriber) && subscriber
    end

    it "returns empty metadata for unsupported files without raising" do
      allow(analyzer).to receive(:open_vips_image).and_return(nil)
      expect(analyzer.metadata).to eq({})
    end
  end
end
