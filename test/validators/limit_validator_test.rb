# frozen_string_literal: true

require 'test_helper'
require 'validators/shared_examples/checks_validator_validity'
require 'validators/shared_examples/works_with_all_rails_common_validation_options'

describe ActiveStorageValidations::LimitValidator do
  include ValidatorHelpers

  let(:validator_test_class) { Limit::Validator }
  let(:params) { {} }

  describe '#check_validity!' do
    include ChecksValidatorValidity

    describe 'arguments validity' do
      describe 'when the passed argument to min or max is not an integer' do
        subject { validator_test_class::CheckValidityInvalidArgument.new(params) }

        let(:error_message) { 'You must pass integers to :min and :max' }

        it 'raises an error at model initialization' do
          assert_raises(ArgumentError, error_message) { subject }
        end
      end

      describe 'when min is higher than max' do
        subject { validator_test_class::CheckValidityMaxHigherThanMin.new(params) }

        let(:error_message) { 'You must pass a higher value to :max than to :min' }

        it 'raises an error at model initialization' do
          assert_raises(ArgumentError, error_message) { subject }
        end
      end

      describe 'when the passed min and/or max are/is a Proc' do
        subject { validator_test_class::CheckValidityProcOption.new(params) }

        it 'does not perform a check, and therefore is valid' do
          assert_nothing_raised { subject }
        end
      end
    end
  end

  describe 'Validator checks' do
    describe ':min' do
      # validates :min, limit: { min: 2 }
      # validates :min_proc, limit: { min: -> (record) { 2 } }
      %w(value proc).each do |value_type|
        describe value_type do
          let(:model) { "#{validator_test_class}::CheckMin#{'Proc' if value_type == 'proc'}".constantize.new(params) }
          let(:attribute) { :"min#{'_proc' if value_type == 'proc'}" }

          describe 'when provided with a right number of files' do
            subject { model.public_send(attribute).attach([file_1, file_2]) and model }

            let(:file_1) { png_file }
            let(:file_2) { gif_file }

            it { is_expected_to_be_valid }
          end

          describe 'when provided with a wrong number of files' do
            subject { model.public_send(attribute).attach(file_1) and model }

            let(:file_1) { png_file }
            let(:error_options) do
              {
                min: 2,
                max: nil,
              }
            end

            it { is_expected_not_to_be_valid }
            it { is_expected_to_have_error_message("limit_out_of_range", error_options: error_options) }
            it { is_expected_to_have_error_options(error_options) }
          end
        end
      end
    end

    describe ':max' do
      # validates :max, limit: { max: 1 }
      # validates :max_proc, limit: { max: -> (record) { 1 } }
      %w(value proc).each do |value_type|
        describe value_type do
          let(:model) { "#{validator_test_class}::CheckMax#{'Proc' if value_type == 'proc'}".constantize.new(params) }
          let(:attribute) { :"max#{'_proc' if value_type == 'proc'}" }

          describe 'when provided with a right number of files' do
            subject { model.public_send(attribute).attach(file_1) and model }

            let(:file_1) { png_file }

            it { is_expected_to_be_valid }
          end

          describe 'when provided with a wrong number of files' do
            subject { model.public_send(attribute).attach([file_1, file_2]) and model }

            let(:file_1) { png_file }
            let(:file_2) { gif_file }
            let(:error_options) do
              {
                min: nil,
                max: 1,
              }
            end

            it { is_expected_not_to_be_valid }
            it { is_expected_to_have_error_message("limit_out_of_range", error_options: error_options) }
            it { is_expected_to_have_error_options(error_options) }
          end
        end
      end
    end
  end

  describe 'Rails options' do
    include WorksWithAllRailsCommonValidationOptions
  end
end
