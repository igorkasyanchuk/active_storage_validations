# frozen_string_literal: true

require "rails_helper"

RSpec.describe ActiveStorageValidations::WithAudioValidator do
  let(:validator_test_class) { WithAudio::Validator }
  let(:params) { {} }

  describe "ASVAttachable shared behavior" do
    it_behaves_like "ASVAttachable"
  end

  describe "#initialize_error_options" do
    it_behaves_like "ASVErrorable"
  end

  describe "Validator checks" do
    let(:model) { validator_test_class::Check.new(params) }

    it_behaves_like "works fine with attachables"

    context "when the video has an audio track" do
      subject(:record) { model.video.attach(video_with_audio_file) and model }

      it { is_expected_to_be_valid }
    end

    context "when the video has no audio track" do
      subject(:record) { model.video.attach(video_file) and model }

      let(:error_options) { { filename: "video" } }

      it { is_expected_not_to_be_valid }
      it { is_expected_to_include_error_message("audio_missing", error_options: error_options) }
      it { is_expected_to_have_error_options(error_options) }

      it "caches the missing audio track metadata" do
        analyzer = instance_double(ActiveStorageValidations::Analyzer::VideoAnalyzer)
        allow(ActiveStorageValidations::Analyzer::VideoAnalyzer).to receive(:new).and_return(analyzer)
        allow(analyzer).to receive(:metadata).and_return({ audio: false })
        model.video.attach(video_file)

        expect(model.valid?).to be(false)
        expect(model.valid?).to be(false)
        expect(analyzer).to have_received(:metadata).once
      end
    end

    context "when no video is attached" do
      subject(:record) { model }

      it { is_expected_to_be_valid }
    end

    describe "when the attached file is missing from storage" do
      let(:attribute) { :video }
      let(:file_for_attachment_missing) { video_with_audio_file }

      it_behaves_like "reports attachment_missing"
    end
  end

  describe "Blob Metadata" do
    let(:attachable) { video_with_audio_file }

    it_behaves_like "is performance optimized"
  end

  describe "Rails options" do
    it_behaves_like "works with all rails common validation options"
  end
end
