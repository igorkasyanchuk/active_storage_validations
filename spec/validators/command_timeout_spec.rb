# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Validator command timeout integration" do
  after do
    ActiveStorageValidations.command_timeout = 10.seconds
  end

  describe "analyzer_timeout_options" do
    it "passes timeout from validator options to analyzers" do
      validator = ActiveStorageValidations::DurationValidator.new(
        attributes: [ :audio ],
        less_than: 5.minutes,
        timeout: 2.seconds
      )

      expect(validator.send(:analyzer_timeout_options)).to eq({ timeout: 2.seconds })
    end

    it "does not pass timeout when the option is absent" do
      validator = ActiveStorageValidations::DurationValidator.new(
        attributes: [ :audio ],
        less_than: 5.minutes
      )

      expect(validator.send(:analyzer_timeout_options)).to eq({})
    end

    it "passes an explicit nil timeout to disable the deadline" do
      validator = ActiveStorageValidations::ProcessableFileValidator.new(
        attributes: [ :has_to_be_processable ],
        timeout: nil
      )

      expect(validator.send(:analyzer_timeout_options)).to eq({ timeout: nil })
    end
  end

  describe "timeout is not treated as a comparison bound" do
    it "accepts timeout alongside duration comparison options" do
      validator = ActiveStorageValidations::DurationValidator.new(
        attributes: [ :audio ],
        less_than: 5.minutes,
        timeout: 2.seconds
      )

      expect { validator.check_validity! }.not_to raise_error

      flat = validator.send(:flatten_options, Object.new, validator.options)
      expect(flat[:less_than]).to eq(5.minutes)
      expect(flat[:timeout]).not_to eq(2.seconds)
      expect(flat.key?(:equal_to)).to be(false)
    end

    it "accepts timeout alongside size comparison options" do
      validator = ActiveStorageValidations::SizeValidator.new(
        attributes: [ :file ],
        less_than: 1.megabyte,
        timeout: 3.seconds
      )

      expect { validator.check_validity! }.not_to raise_error

      flat = validator.send(:flatten_options, Object.new, validator.options)
      expect(flat[:less_than]).to eq(1.megabyte)
      expect(flat[:timeout]).not_to eq(3.seconds)
    end
  end

  context "when analysis returns empty metadata after a timeout" do
    let(:model) { ProcessableFile::Validator::Check.new }
    let(:error_options) { { filename: "image_150x150_file.png" } }

    it "adds the existing file_not_processable error" do
      allow_any_instance_of(ActiveStorageValidations::Analyzer::ImageAnalyzer::ImageMagick).to receive(:metadata).and_return({})
      allow_any_instance_of(ActiveStorageValidations::Analyzer::ImageAnalyzer::Vips).to receive(:metadata).and_return({})

      model.has_to_be_processable.attach(image_150x150_file)

      expect(model.valid?).to be(false)
      expect(
        model.errors.map { |error| error.options[:validator_type] }
      ).to include(:processable_file)
    end
  end

  context "when duration analysis returns empty metadata after a timeout" do
    let(:model) { Duration::Validator::Check.new }

    it "adds the existing media_metadata_missing error" do
      allow_any_instance_of(ActiveStorageValidations::Analyzer::VideoAnalyzer).to receive(:metadata).and_return({})
      allow_any_instance_of(ActiveStorageValidations::Analyzer::AudioAnalyzer).to receive(:metadata).and_return({})

      model.less_than.attach(audio_file)

      expect(model.valid?).to be(false)
      expect(model.errors.any? { |error|
        error.type == :media_metadata_missing || error.message.include?("not a valid media file")
      }).to be(true)
    end
  end

  context "when a timeout leaves empty analysis results" do
    it "does not persist asv_* keys so a later validation can retry analysis" do
      model = Dimension::Validator::Check.new
      model.width_min.attach(image_500x500_file)

      allow_any_instance_of(ActiveStorageValidations::Analyzer::ImageAnalyzer::ImageMagick).to receive(:metadata).and_return({})
      allow_any_instance_of(ActiveStorageValidations::Analyzer::ImageAnalyzer::Vips).to receive(:metadata).and_return({})

      expect(model.valid?).to be(false)

      custom_keys = model.width_min.blob.metadata.fetch("custom", {}).keys
      asv_keys = custom_keys.select { |key| key.to_s.start_with?("asv_") }
      expect(asv_keys).to be_empty

      allow_any_instance_of(ActiveStorageValidations::Analyzer::ImageAnalyzer::ImageMagick).to receive(:metadata).and_call_original
      allow_any_instance_of(ActiveStorageValidations::Analyzer::ImageAnalyzer::Vips).to receive(:metadata).and_call_original

      model.errors.clear
      expect(model.valid?).to be(true), "expected analysis to retry and succeed when no asv_* keys were cached"
    end
  end

  context "when content_type spoofing protection times out" do
    let(:model) { ContentType::Validator::Check.new }

    it "fails closed with a content_type error instead of raising" do
      model.spoofing_protection.attach(jpeg_file)

      begin
        allow_any_instance_of(ActiveStorageValidations::Analyzer::ContentTypeAnalyzer).to receive(:content_type).and_return(nil)

        expect(model.valid?).to be(false)
        expect(model.errors.any? { |error|
          error.options[:validator_type] == :content_type ||
            error.type.to_s.include?("content_type")
        }).to be(true)
      rescue StandardError => error
        fail "spoofing protection raised #{error.class}: #{error.message} after analyzer timeout"
      end
    end
  end
end
