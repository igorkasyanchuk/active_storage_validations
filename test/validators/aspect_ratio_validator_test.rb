# frozen_string_literal: true

require "test_helper"
require "validators/shared_examples/checks_validator_validity"
require "validators/shared_examples/is_performance_optimized"
require "validators/shared_examples/works_fine_with_attachables"
require "validators/shared_examples/works_with_all_rails_common_validation_options"

describe ActiveStorageValidations::AspectRatioValidator do
  include ValidatorHelpers

  let(:validator_test_class) { AspectRatio::Validator }
  let(:params) { {} }

  describe "#check_validity!" do
    include ChecksValidatorValidity

    describe "aspect ratio validity" do
      describe "when the passed option is an invalid" do
        let(:error_message) do
          <<~ERROR_MESSAGE
            You must pass a valid aspect ratio to the validator
            It should either be a named aspect ratio (#{ActiveStorageValidations::AspectRatioValidator::NAMED_ASPECT_RATIOS.join(', ')})
            Or an aspect ratio like 'is_16_9' (matching /#{ActiveStorageValidations::AspectRatioValidator::ASPECT_RATIO_REGEX.source}/)
          ERROR_MESSAGE
        end

        describe "named aspect ratio" do
          subject { validator_test_class::CheckValidityInvalidNamedArgument.new(params) }

          it "raises an error at model initialization" do
            assert_raises(ArgumentError, error_message) { subject }
          end
        end

        describe "is_x_y aspect ratio" do
          subject { validator_test_class::CheckValidityInvalidIsXyArgument.new(params) }

          it "raises an error at model initialization" do
            assert_raises(ArgumentError, error_message) { subject }
          end
        end
      end

      describe "when the passed option is a Proc" do
        subject { validator_test_class::CheckValidityProcOption.new(params) }

        it "does not perform a check, and therefore is valid" do
          assert_nothing_raised { subject }
        end
      end
    end
  end

  describe "ASPECT_RATIO_REGEX" do
    let(:aspect_ratio_regex) { ActiveStorageValidations::AspectRatioValidator::ASPECT_RATIO_REGEX }
    let(:accepted_is_x_y_strings) do
      %w[
        is_16_9
        is_4_5
        is_69_25
        is_143_100
      ]
    end
    let(:not_accepted_is_x_y_strings) do
      %w[
        is__1
        is_5_
        is_square
        is_0_1
        is_1_0
        is_0_0
        is_01_2
      ]
    end

    it "accepts ratios like 'is_16_9'" do
      accepted_is_x_y_strings.each do |accepted_is_x_y_string|
        _(accepted_is_x_y_string).must_match(aspect_ratio_regex)
      end

      not_accepted_is_x_y_strings.each do |not_accepted_is_x_y_string|
        _(not_accepted_is_x_y_string).wont_match(aspect_ratio_regex)
      end
    end
  end

  describe "Validator checks" do
    include WorksFineWithAttachables

    let(:model) { validator_test_class::Check.new(params) }

    describe ":with" do
      # validates :with_named_square, aspect_ratio: :square
      # validates :with_named_portrait, aspect_ratio: :portrait
      # validates :with_named_landscape, aspect_ratio: :landscape
      # validates :with_named_square_proc, aspect_ratio: -> (record) { :square }
      # validates :with_named_portrait_proc, aspect_ratio: -> (record) { :portrait }
      # validates :with_named_landscape_proc, aspect_ratio: -> (record) { :landscape }
      %w[value proc].each do |value_type|
        describe "named aspect_ratio" do
          %i[square portrait landscape].each do |named_aspect_ratio|
            describe ":#{named_aspect_ratio}" do
              let(:attribute) { :"with_#{named_aspect_ratio}#{'_proc' if value_type == 'proc'}" }

              describe "when provided with an allowed aspect_ratio file" do
                subject { model.public_send(attribute).attach(allowed_file) and model }

                let(:allowed_file) do
                  case named_aspect_ratio
                  when :square then square_image_file
                  when :portrait then portrait_image_file
                  when :landscape then landscape_image_file
                  end
                end

                it { is_expected_to_be_valid }
              end

              describe "when provided with a not allowed aspect_ratio file" do
                subject { model.public_send(attribute).attach(not_allowed_file) and model }

                let(:not_allowed_file) do
                  case named_aspect_ratio
                  when :square then portrait_image_file
                  when :portrait then landscape_image_file
                  when :landscape then square_image_file
                  end
                end
                let(:width) do
                  case named_aspect_ratio
                  when :square then 600
                  when :portrait then 700
                  when :landscape then 150
                  end
                end
                let(:height) do
                  case named_aspect_ratio
                  when :square then 800
                  when :portrait then 500
                  when :landscape then 150
                  end
                end
                let(:error_options) do
                  {
                    authorized_aspect_ratios: named_aspect_ratio.to_s,
                    width: width,
                    height: height,
                    filename: not_allowed_file[:filename]
                  }
                end

                it { is_expected_not_to_be_valid }
                it { is_expected_to_include_error_message("aspect_ratio_not_#{named_aspect_ratio}", error_options: error_options) }
                it { is_expected_to_have_error_options(error_options) }
              end
            end
          end
        end

        describe "regex aspect_ratio" do
          let(:attribute) { :"with_regex#{'_proc' if value_type == 'proc'}" }

          describe "when provided with an allowed aspect_ratio file" do
            subject { model.public_send(attribute).attach(allowed_file) and model }

            let(:allowed_file) { is_16_9_image_file }

            it { is_expected_to_be_valid }
          end

          describe "when provided with a not allowed aspect_ratio file" do
            subject { model.public_send(attribute).attach(not_allowed_file) and model }

            let(:not_allowed_file) { is_4_3_image_file }
            let(:error_options) do
              {
                authorized_aspect_ratios: "16:9",
                width: 1200,
                height: 900,
                filename: not_allowed_file[:filename]
              }
            end

            it { is_expected_not_to_be_valid }
            it { is_expected_to_include_error_message("aspect_ratio_not_x_y", error_options: error_options) }
            it { is_expected_to_have_error_options(error_options) }
          end
        end
      end
    end

    describe ":in" do
      %w[value proc].each do |value_type|
        describe value_type do
          let(:attribute) { :"in_aspect_ratios#{'_proc' if value_type == 'proc'}" }

          describe "when provided with an allowed aspect_ratio file" do
            subject { model.public_send(attribute).attach(allowed_file) and model }

            let(:allowed_file) { [ square_image_file, portrait_image_file, is_16_9_image_file ].sample }

            it { is_expected_to_be_valid }
          end

          describe "when provided with a not allowed aspect_ratio file" do
            subject { model.public_send(attribute).attach(not_allowed_file) and model }

            let(:not_allowed_file) { is_4_3_image_file }

            let(:error_options) do
              {
                authorized_aspect_ratios: "square, portrait, 16:9",
                width: 1200,
                height: 900,
                filename: not_allowed_file[:filename]
              }
            end

            it { is_expected_not_to_be_valid }
            it { is_expected_to_include_error_message("aspect_ratio_invalid", error_options: error_options) }
            it { is_expected_to_have_error_options(error_options) }
          end
        end
      end
    end

    describe "Edge cases" do
      describe "when the passed file is not a valid media" do
        subject { model.public_send(attribute).attach(empty_io_file) and model }

        let(:attribute) { :with_invalid_media_file }
        let(:error_options) do
          {
            filename: empty_io_file[:filename]
          }
        end

        it { is_expected_not_to_be_valid }
        it { is_expected_to_include_error_message("media_metadata_missing", error_options: error_options) }
        it { is_expected_to_have_error_options(error_options) }
      end

      describe "when the passed file is a pdf" do
        describe "valid pdf" do
          subject { model.public_send(attribute).attach(pdf_150x150_file) and model }

          let(:attribute) { :with_pdf_file }
          let(:error_options) do
            {
              filename: pdf_150x150_file[:filename]
            }
          end

          it { is_expected_to_be_valid }
        end

        describe "invalid pdf" do
          subject { model.public_send(attribute).attach(pdf_200x300_file) and model }

          let(:attribute) { :with_pdf_file }
          let(:error_options) do
            {
              authorized_aspect_ratios: "square",
              width: 200,
              height: 300,
              filename: pdf_200x300_file[:filename]
            }
          end

          it { is_expected_not_to_be_valid }
          it { is_expected_to_include_error_message("aspect_ratio_not_square", error_options: error_options) }
          it { is_expected_to_have_error_options(error_options) }
        end
      end
    end
  end

  describe "Blob Metadata" do
    let(:attachable) do
      {
        io: File.open(Rails.root.join("public", "image_150x150.png")),
        filename: "image_150x150.png",
        content_type: "image/png"
      }
    end

    include IsPerformanceOptimized
  end

  describe "Rails options" do
    include WorksWithAllRailsCommonValidationOptions
  end
end
