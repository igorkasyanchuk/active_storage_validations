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
  let(:media_io) { open_fixture(media_path) }
  let(:media_content_type) { "video/mp4" }
  let(:media_content_type_rotated) { media_content_type }
  let(:expected_metadata) { { width: 150, height: 150, duration: 1.733, audio: false, video: true } }
  let(:expected_metadata_over_10ko) { { width: 150, height: 150, duration: 9.643, audio: false, video: true } }
  let(:expected_metadata_rotated) { { width: 700, height: 500, duration: 1.733, audio: false, video: true } }

  it_behaves_like "returns the right metadata for any attachable"

  describe "rotation" do
    subject(:metadata) { analyzer.metadata }

    let(:attachable) { video_file }
    let(:video_stream) { { "codec_type" => "video", "width" => 700, "height" => 500 }.merge(rotation) }

    before do
      allow(analyzer).to receive(:media_from_path).and_return({ "streams" => [ video_stream ], "format" => { "duration" => "1.7" } })
    end

    context "when the rotate tag is a decimal string (e.g. \"90.0\")" do
      let(:rotation) { { "tags" => { "rotate" => "90.0" } } }

      it "swaps width and height" do
        expect(metadata).to include(width: 500, height: 700, angle: 90)
      end
    end

    context "when the Display Matrix rotation is a float" do
      let(:rotation) { { "side_data_list" => [ { "side_data_type" => "Display Matrix", "rotation" => -90.0 } ] } }

      it "swaps width and height" do
        expect(metadata).to include(width: 500, height: 700, angle: -90)
      end
    end

    context "when the rotation cannot be parsed" do
      let(:rotation) { { "tags" => { "rotate" => "unknown" } } }

      it "ignores it instead of raising" do
        expect(metadata).to include(width: 700, height: 500)
        expect(metadata).not_to have_key(:angle)
      end
    end
  end

  describe "timeouts" do
    let(:path) { Rails.root.join("public", "video_150x150.mp4").to_s }
    let(:attachable) do
      {
        io: open_fixture(path),
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

  describe "duration precision" do
    subject(:metadata) { analyzer.metadata }

    let(:attachable) { video_file }

    before do
      allow(analyzer).to receive(:media_from_path).and_return(
        {
          "streams" => [ { "codec_type" => "video", "width" => 150, "height" => 150, "duration" => "1.96" } ],
          "format" => {}
        }
      )
    end

    it "keeps sub-second precision instead of rounding to 0.1s" do
      expect(metadata[:duration]).to eq(1.96)
    end
  end

  describe "malformed ffprobe output" do
    let(:attachable) { video_file }

    context "when ffprobe returns invalid JSON" do
      subject(:metadata) { analyzer.metadata }

      before { allow(analyzer).to receive(:run_command).and_return(successful_command_result("{")) }

      it "returns empty metadata instead of raising" do
        expect { metadata }.not_to raise_error
        expect(metadata).to eq({})
      end
    end

    context "when duration is N/A" do
      subject(:metadata) { analyzer.metadata }

      before do
        allow(analyzer).to receive(:media_from_path).and_return(
          {
            "streams" => [ { "codec_type" => "video", "width" => 150, "height" => 150, "duration" => "N/A" } ],
            "format" => { "duration" => "N/A" }
          }
        )
      end

      it "omits duration instead of raising" do
        expect { metadata }.not_to raise_error
        expect(metadata).to include(width: 150, height: 150)
        expect(metadata).not_to have_key(:duration)
      end
    end
  end

  describe "empty container" do
    subject(:metadata) { analyzer.metadata }

    let(:attachable) { video_file }

    context "when ffprobe succeeds with no audio or video streams" do
      before do
        allow(analyzer).to receive(:media_from_path).and_return(
          {
            "streams" => [],
            "format" => { "nb_streams" => 0, "format_name" => "mov,mp4,m4a,3gp,3g2,mj2", "duration" => "0.000000" }
          }
        )
      end

      it "returns empty metadata so processable_file fails closed" do
        expect(metadata).to eq({})
      end
    end

    context "when ffprobe reports only a data stream" do
      before do
        allow(analyzer).to receive(:media_from_path).and_return(
          {
            "streams" => [ { "codec_type" => "data" } ],
            "format" => { "duration" => "1.0" }
          }
        )
      end

      it "returns empty metadata" do
        expect(metadata).to eq({})
      end
    end

    context "when the container has an audio stream but no video stream" do
      before do
        allow(analyzer).to receive(:media_from_path).and_return(
          {
            "streams" => [ { "codec_type" => "audio", "duration" => "1.5", "sample_rate" => "44100" } ],
            "format" => { "duration" => "1.5" }
          }
        )
      end

      it "keeps the audio analysis" do
        expect(metadata).to eq({ duration: 1.5, audio: true, video: false })
      end
    end
  end
end
