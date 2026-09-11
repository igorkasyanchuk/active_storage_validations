# frozen_string_literal: true

require "rails_helper"
require "analyzers/support/analyzer_helpers"

RSpec.describe ActiveStorageValidations::Analyzer::AudioAnalyzer do
  def self.test_rotatable_media?
    true
  end

  let(:analyzer) { described_class.new(attachable) }

  let(:media_extension) { ".mp3" }
  let(:media_filename) { "audio#{media_extension}" }
  let(:media_filename_over_10ko) { "audio_2s#{media_extension}" }
  let(:media_filename_rotated) { "audio#{media_extension}" }
  let(:media_filename_0ko) { "audio_0ko#{media_extension}" }
  let(:media_path) { Rails.root.join("public", media_filename) }
  let(:media_io) { open_fixture(media_path) }
  let(:media_content_type) { "audio/mp3" }
  let(:media_content_type_rotated) { media_content_type }
  let(:expected_metadata) { { duration: 1.0, bit_rate: 32000, sample_rate: 44100, audio: true } }
  let(:expected_metadata_over_10ko) { { duration: 2.0, bit_rate: 107286, sample_rate: 44100, audio: true } }
  let(:expected_metadata_rotated) { { duration: 1.0, bit_rate: 32000, sample_rate: 44100, audio: true } }

  it_behaves_like "returns the right metadata for any attachable"

  describe "#metadata" do
    subject(:metadata) { analyzer.metadata }

    context "when the audio stream has tags (ID3 / Vorbis comments)" do
      let(:attachable) { audio_1s_tagged }

      # Tags are free-form and can be large / non-ASCII; everything returned here
      # ends up in the blob custom metadata that Active Storage sends to S3 / GCS
      # (see storage_metadata_constraints_spec.rb).
      it "does not extract them" do
        expect(metadata).to eq({ duration: 1.0, sample_rate: 48000, audio: true })
      end
    end
  end

  describe "timeouts" do
    let(:path) { Rails.root.join("public", "audio_2s.mp3").to_s }
    let(:attachable) do
      {
        io: open_fixture(path),
        filename: "audio_2s.mp3",
        content_type: "audio/mpeg"
      }
    end
    let(:analyzer) { described_class.new(attachable, timeout: 0.2) }

    after { ActiveStorageValidations.command_timeout = 10.seconds }

    it "returns empty metadata when ffprobe times out" do
      allow(analyzer).to receive(:run_command).and_return(timed_out_command_result)
      expect(analyzer.metadata).to eq({})
    end
  end
end
