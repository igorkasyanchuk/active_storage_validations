# frozen_string_literal: true

require 'test_helper'
require 'validators/shared_examples/checks_validator_validity'
require 'validators/shared_examples/works_with_all_rails_common_validation_options'

describe ActiveStorageValidations::AspectRatioValidator do
  include ValidatorHelpers

  let(:validator_test_class) { AspectRatio::Validator }
  let(:params) { {} }

  describe '#check_validity!' do
    include ChecksValidatorValidity

    describe 'aspect ratio validity' do
      describe 'when the passed option is an invalid' do
        let(:error_message) do
          <<~ERROR_MESSAGE
            You must pass a valid aspect ratio to the validator
            It should either be a named aspect ratio (#{ActiveStorageValidations::AspectRatioValidator::NAMED_ASPECT_RATIOS.join(', ')})
            Or an aspect ratio like 'is_16_9' (matching /#{ActiveStorageValidations::AspectRatioValidator::ASPECT_RATIO_REGEX.source}/)
          ERROR_MESSAGE
        end

        describe 'named aspect ratio' do
          subject { validator_test_class::CheckValidityInvalidNamedArgument.new(params) }

          it 'raises an error at model initialization' do
            assert_raises(ArgumentError, error_message) { subject }
          end
        end

        describe 'is_x_y aspect ratio' do
          subject { validator_test_class::CheckValidityInvalidIsXyArgument.new(params) }

          it 'raises an error at model initialization' do
            assert_raises(ArgumentError, error_message) { subject }
          end
        end
      end

      describe 'when the passed option is a Proc' do
        subject { validator_test_class::CheckValidityProcOption.new(params) }

        it 'does not perform a check, and therefore is valid' do
          assert_nothing_raised { subject }
        end
      end
    end
  end

  describe 'ASPECT_RATIO_REGEX' do
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

  describe 'Rails options' do
    include WorksWithAllRailsCommonValidationOptions
  end
end
