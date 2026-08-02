# frozen_string_literal: true

require "rails_helper"
require "analyzers/support/analyzer_helpers"

RSpec.describe ActiveStorageValidations::Analyzer::ImageAnalyzer::ImageMagick do
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
    let(:analyzer) { described_class.new(attachable, timeout: 5.seconds) }

    after { ActiveStorageValidations.command_timeout = 10.seconds }

    it "returns nil from media_from_path when identify times out" do
      allow(analyzer).to receive(:run_command).and_return(timed_out_command_result)
      expect(analyzer.send(:media_from_path, path)).to be_nil
    end

    it "runs identify through run_command" do
      seen_argv = nil
      real_run = analyzer.method(:run_command)

      allow(analyzer).to receive(:run_command) do |*args, **kwargs|
        seen_argv = args
        real_run.call(*args, **kwargs)
      end

      info = analyzer.send(:media_from_path, path)

      expect(info.valid?).to be(true)
      expect(info.width).to eq(150)
      expect(info.height).to eq(150)
      expect(seen_argv.any? { |part| part.to_s.include?("identify") || part.to_s == "magick" }).to be(true)
    end

    it "returns empty metadata when identify times out during metadata" do
      allow(analyzer).to receive(:run_command).and_return(timed_out_command_result)
      expect(analyzer.metadata).to eq({})
    end
  end

  describe "#parse_identify_output" do
    let(:path) { Rails.root.join("public", "image_150x150.png").to_s }
    let(:attachable) do
      {
        io: File.open(path),
        filename: "image_150x150.png",
        content_type: "image/png"
      }
    end
    let(:analyzer) { described_class.new(attachable, timeout: 5.seconds) }

    it "marks empty stdout as invalid without raising" do
      info = analyzer.send(:parse_identify_output, "")

      expect(info.valid?).to be(false)
      expect(info.width).to eq(0)
      expect(info.height).to eq(0)
    end

    it "marks garbage stdout as invalid without raising" do
      info = analyzer.send(:parse_identify_output, "not-a-dimension")

      expect(info.valid?).to be(false)
    end

    it "uses the first frame of multi-frame identify output" do
      stdout = "150\t150\tUndefined\n300\t200\tRightTop\n"
      info = analyzer.send(:parse_identify_output, stdout)

      expect(info.valid?).to be(true)
      expect(info.width).to eq(150)
      expect(info.height).to eq(150)
      # Trailing frames leave junk after the first tab-split; rotation must not crash.
      expect(analyzer.send(:rotated_image?, info)).to be(false)
    end
  end
end
