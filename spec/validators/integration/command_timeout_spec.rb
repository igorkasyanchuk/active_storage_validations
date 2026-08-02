# frozen_string_literal: true

require "rails_helper"

RSpec.describe "command timeout integration" do
  after do
    ActiveStorageValidations.command_timeout = 10.seconds
  end

  describe "#analyzer_timeout_options" do
    subject(:timeout_options) { validator.send(:analyzer_timeout_options) }

    context "when timeout is set on the validator" do
      let(:validator) do
        ActiveStorageValidations::DurationValidator.new(
          attributes: [ :audio ],
          less_than: 5.minutes,
          timeout: 2.seconds
        )
      end

      it "passes timeout through to analyzers" do
        expect(timeout_options).to eq({ timeout: 2.seconds })
      end
    end

    context "when timeout is absent" do
      let(:validator) do
        ActiveStorageValidations::DurationValidator.new(
          attributes: [ :audio ],
          less_than: 5.minutes
        )
      end

      it "does not pass timeout" do
        expect(timeout_options).to eq({})
      end
    end

    context "when timeout is explicitly nil" do
      let(:validator) do
        ActiveStorageValidations::ProcessableFileValidator.new(
          attributes: [ :has_to_be_processable ],
          timeout: nil
        )
      end

      it "passes nil to disable the deadline" do
        expect(timeout_options).to eq({ timeout: nil })
      end
    end
  end

  describe "timeout is not treated as a comparison bound" do
    context "with a duration comparison option" do
      let(:validator) do
        ActiveStorageValidations::DurationValidator.new(
          attributes: [ :audio ],
          less_than: 5.minutes,
          timeout: 2.seconds
        )
      end

      it "accepts timeout alongside the comparison option" do
        expect { validator.check_validity! }.not_to raise_error
      end

      it "keeps timeout out of flattened comparison options" do
        flat = validator.send(:flatten_options, Object.new, validator.options)

        expect(flat[:less_than]).to eq(5.minutes)
        expect(flat[:timeout]).not_to eq(2.seconds)
        expect(flat.key?(:equal_to)).to be(false)
      end
    end

    context "with a size comparison option" do
      let(:validator) do
        ActiveStorageValidations::SizeValidator.new(
          attributes: [ :file ],
          less_than: 1.megabyte,
          timeout: 3.seconds
        )
      end

      it "accepts timeout alongside the comparison option" do
        expect { validator.check_validity! }.not_to raise_error
      end

      it "keeps timeout out of flattened comparison options" do
        flat = validator.send(:flatten_options, Object.new, validator.options)

        expect(flat[:less_than]).to eq(1.megabyte)
        expect(flat[:timeout]).not_to eq(3.seconds)
      end
    end
  end

  context "when analysis returns empty metadata after a timeout" do
    subject(:valid) { model.valid? }

    before do
      allow_any_instance_of(ActiveStorageValidations::Analyzer::ImageAnalyzer::ImageMagick).to receive(:metadata).and_return({})
      allow_any_instance_of(ActiveStorageValidations::Analyzer::ImageAnalyzer::Vips).to receive(:metadata).and_return({})
      model.has_to_be_processable.attach(image_150x150_file)
    end

    let(:model) { ProcessableFile::Validator::Check.new }

    it "is invalid" do
      expect(valid).to be(false)
    end

    it "adds the existing file_not_processable error" do
      valid
      expect(
        model.errors.map { |error| error.options[:validator_type] }
      ).to include(:processable_file)
    end
  end

  context "when duration analysis returns empty metadata after a timeout" do
    subject(:valid) { model.valid? }

    before do
      allow_any_instance_of(ActiveStorageValidations::Analyzer::VideoAnalyzer).to receive(:metadata).and_return({})
      allow_any_instance_of(ActiveStorageValidations::Analyzer::AudioAnalyzer).to receive(:metadata).and_return({})
      model.less_than.attach(audio_file)
    end

    let(:model) { Duration::Validator::Check.new }

    it "is invalid" do
      expect(valid).to be(false)
    end

    it "adds the existing media_metadata_missing error" do
      valid
      expect(model.errors.any? { |error|
        error.type == :media_metadata_missing || error.message.include?("not a valid media file")
      }).to be(true)
    end
  end

  context "when a timeout leaves empty analysis results" do
    subject(:valid) { model.valid? }

    let(:model) { Dimension::Validator::Check.new }

    before do
      model.width_min.attach(image_500x500_file)
      allow_any_instance_of(ActiveStorageValidations::Analyzer::ImageAnalyzer::ImageMagick).to receive(:metadata).and_return({})
      allow_any_instance_of(ActiveStorageValidations::Analyzer::ImageAnalyzer::Vips).to receive(:metadata).and_return({})
    end

    it "is invalid" do
      expect(valid).to be(false)
    end

    it "does not persist asv_* keys" do
      valid
      custom_keys = model.width_min.blob.metadata.fetch("custom", {}).keys
      asv_keys = custom_keys.select { |key| key.to_s.start_with?("asv_") }
      expect(asv_keys).to be_empty
    end

    context "when analysis succeeds on a later validation" do
      before do
        valid
        allow_any_instance_of(ActiveStorageValidations::Analyzer::ImageAnalyzer::ImageMagick).to receive(:metadata).and_call_original
        allow_any_instance_of(ActiveStorageValidations::Analyzer::ImageAnalyzer::Vips).to receive(:metadata).and_call_original
        model.errors.clear
      end

      it "retries analysis and succeeds" do
        expect(model.valid?).to be(true)
      end
    end
  end

  context "when content_type spoofing protection times out" do
    subject(:valid) { model.valid? }

    let(:model) { ContentType::Validator::Check.new }

    before do
      model.spoofing_protection.attach(jpeg_file)
      allow_any_instance_of(ActiveStorageValidations::Analyzer::ContentTypeAnalyzer).to receive(:content_type).and_return(nil)
    end

    it "does not raise" do
      expect { valid }.not_to raise_error
    end

    it "is invalid" do
      expect(valid).to be(false)
    end

    it "adds a content_type error" do
      valid
      expect(model.errors.any? { |error|
        error.options[:validator_type] == :content_type ||
          error.type.to_s.include?("content_type")
      }).to be(true)
    end
  end
end
