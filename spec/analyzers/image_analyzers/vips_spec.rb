# frozen_string_literal: true

require "rails_helper"
require "analyzers/support/analyzer_helpers"

RSpec.describe ActiveStorageValidations::Analyzer::ImageAnalyzer::Vips do
  def self.test_rotatable_media?
    true
  end

  let(:analyzer) { described_class.new(attachable) }

  # Uncomment these lines in development, or launch test with ENV['IMAGE_PROCESSOR'] = :vips
  # before do
  #   @original_variant_processor = Rails.application.config.active_storage.variant_processor
  #   Rails.application.config.active_storage.variant_processor = :vips
  #   ActiveStorage.variant_processor = :vips
  # end

  # after do
  #   Rails.application.config.active_storage.variant_processor = @original_variant_processor
  #   ActiveStorage.variant_processor = @original_variant_processor
  # end

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
  let(:media_io) { File.open(media_path) }
  let(:media_content_type) { "image/png" }
  let(:media_content_type_rotated) { "image/jpeg" }
  let(:expected_metadata) { { width: 150, height: 150 } }
  let(:expected_metadata_over_10ko) { { width: 150, height: 150 } }
  let(:expected_metadata_rotated) { { width: 700, height: 500 } }

  it_behaves_like "returns the right metadata for any attachable"

  describe "timeouts" do
    let(:path) { Rails.root.join("public", "image_150x150.png").to_s }
    let(:attachable) do
      {
        io: File.open(path),
        filename: "image_150x150.png",
        content_type: "image/png"
      }
    end
    let(:analyzer) { described_class.new(attachable, timeout: 0.1) }

    after { ActiveStorageValidations.command_timeout = 10.seconds }

    it "returns empty metadata and emits timeout when the load exceeds the deadline" do
      skip "requires the ruby-vips gem" unless analyzer.send(:supported?)

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
      skip "requires the ruby-vips gem" unless analyzer.send(:supported?)

      allow(analyzer).to receive(:open_vips_image).and_return(nil)
      expect(analyzer.metadata).to eq({})
    end
  end
end
