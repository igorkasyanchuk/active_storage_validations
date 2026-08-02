# frozen_string_literal: true

require "test_helper"

describe "Validator command timeout integration" do
  include ValidatorHelpers

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

      assert_equal({ timeout: 2.seconds }, validator.send(:analyzer_timeout_options))
    end

    it "does not pass timeout when the option is absent" do
      validator = ActiveStorageValidations::DurationValidator.new(
        attributes: [ :audio ],
        less_than: 5.minutes
      )

      assert_equal({}, validator.send(:analyzer_timeout_options))
    end

    it "passes an explicit nil timeout to disable the deadline" do
      validator = ActiveStorageValidations::ProcessableFileValidator.new(
        attributes: [ :has_to_be_processable ],
        timeout: nil
      )

      assert_equal({ timeout: nil }, validator.send(:analyzer_timeout_options))
    end
  end

  describe "timeout is not treated as a comparison bound" do
    it "accepts timeout alongside duration comparison options" do
      validator = ActiveStorageValidations::DurationValidator.new(
        attributes: [ :audio ],
        less_than: 5.minutes,
        timeout: 2.seconds
      )

      assert_nothing_raised { validator.check_validity! }

      flat = validator.send(:flatten_options, Object.new, validator.options)
      assert_equal 5.minutes, flat[:less_than]
      refute_equal 2.seconds, flat[:timeout]
      refute flat.key?(:equal_to)
    end

    it "accepts timeout alongside size comparison options" do
      validator = ActiveStorageValidations::SizeValidator.new(
        attributes: [ :file ],
        less_than: 1.megabyte,
        timeout: 3.seconds
      )

      assert_nothing_raised { validator.check_validity! }

      flat = validator.send(:flatten_options, Object.new, validator.options)
      assert_equal 1.megabyte, flat[:less_than]
      refute_equal 3.seconds, flat[:timeout]
    end
  end

  describe "when analysis returns empty metadata after a timeout" do
    let(:model) { ProcessableFile::Validator::Check.new }
    let(:error_options) { { filename: "image_150x150_file.png" } }

    it "adds the existing file_not_processable error" do
      ActiveStorageValidations::Analyzer::ImageAnalyzer::ImageMagick.stub_any_instance(:metadata, {}) do
        ActiveStorageValidations::Analyzer::ImageAnalyzer::Vips.stub_any_instance(:metadata, {}) do
          model.has_to_be_processable.attach(image_150x150_file)

          refute model.valid?
          assert_includes(
            model.errors.map { |error| error.options[:validator_type] },
            :processable_file
          )
        end
      end
    end
  end

  describe "when duration analysis returns empty metadata after a timeout" do
    let(:model) { Duration::Validator::Check.new }

    it "adds the existing media_metadata_missing error" do
      ActiveStorageValidations::Analyzer::VideoAnalyzer.stub_any_instance(:metadata, {}) do
        ActiveStorageValidations::Analyzer::AudioAnalyzer.stub_any_instance(:metadata, {}) do
          model.less_than.attach(audio_file)

          refute model.valid?
          assert model.errors.any? { |error|
            error.type == :media_metadata_missing || error.message.include?("not a valid media file")
          }
        end
      end
    end
  end

  describe "when a timeout leaves empty analysis results" do
    it "does not persist asv_* keys so a later validation can retry analysis" do
      model = Dimension::Validator::Check.new
      model.width_min.attach(image_500x500_file)

      ActiveStorageValidations::Analyzer::ImageAnalyzer::ImageMagick.stub_any_instance(:metadata, {}) do
        ActiveStorageValidations::Analyzer::ImageAnalyzer::Vips.stub_any_instance(:metadata, {}) do
          refute model.valid?

          custom_keys = model.width_min.blob.metadata.fetch("custom", {}).keys
          asv_keys = custom_keys.select { |key| key.to_s.start_with?("asv_") }
          assert_empty asv_keys
        end
      end

      model.errors.clear
      assert model.valid?, "expected analysis to retry and succeed when no asv_* keys were cached"
    end
  end

  describe "when content_type spoofing protection times out" do
    let(:model) { ContentType::Validator::Check.new }

    it "fails closed with a content_type error instead of raising" do
      model.spoofing_protection.attach(jpeg_file)

      begin
        ActiveStorageValidations::Analyzer::ContentTypeAnalyzer.stub_any_instance(:content_type, nil) do
          valid = model.valid?
          refute valid
          assert model.errors.any? { |error|
            error.options[:validator_type] == :content_type ||
              error.type.to_s.include?("content_type")
          }
        end
      rescue StandardError => error
        flunk "spoofing protection raised #{error.class}: #{error.message} after analyzer timeout"
      end
    end
  end
end
