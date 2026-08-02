# frozen_string_literal: true

require "rails_helper"
require "analyzers/support/analyzer_helpers"

RSpec.describe ActiveStorageValidations::Analyzer::VideoAnalyzer do
  def self.test_rotatable_media?
    true
  end

  let(:analyzer) { described_class.new(attachable) }

  let(:media_extension) { ".mp4" }
  let(:media_filename) { "video_150x150#{media_extension}" }
  let(:media_filename_over_10ko) { "video_150x150_24ko#{media_extension}" }
  let(:media_filename_rotated) { "video_700x500_rotated_90#{media_extension}" }
  let(:media_filename_0ko) { "video_file_0ko#{media_extension}" }
  let(:media_path) { Rails.root.join("public", media_filename) }
  let(:media_io) { File.open(media_path) }
  let(:media_content_type) { "video/mp4" }
  let(:media_content_type_rotated) { media_content_type }
  let(:expected_metadata) { { width: 150, height: 150, duration: 1.7, audio: false, video: true } }
  let(:expected_metadata_over_10ko) { { width: 150, height: 150, duration: 9.6, audio: false, video: true } }
  let(:expected_metadata_rotated) { { width: 700, height: 500, duration: 1.7, audio: false, video: true } }

  it_behaves_like "returns the right metadata for any attachable"

  describe "timeouts" do
    let(:path) { Rails.root.join("public", "video_150x150.mp4").to_s }
    let(:attachable) do
      {
        io: File.open(path),
        filename: "video_150x150.mp4",
        content_type: "video/mp4"
      }
    end
    let(:analyzer) { described_class.new(attachable, timeout: 0.2) }

    after { ActiveStorageValidations.command_timeout = 10.seconds }

    context "when ffprobe times out" do
      before { allow(analyzer).to receive(:run_command).and_return(timed_out_command_result) }

      describe "#media_from_path" do
        subject(:media) { analyzer.send(:media_from_path, path) }

        it { is_expected.to be_nil }
      end

      describe "#metadata" do
        subject(:metadata) { analyzer.metadata }

        it { is_expected.to eq({}) }
      end
    end
  end
end
