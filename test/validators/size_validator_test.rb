# frozen_string_literal: true

require 'test_helper'
require 'validators/shared_examples/checks_validator_validity'
require 'validators/shared_examples/works_with_all_rails_common_validation_options'

describe ActiveStorageValidations::SizeValidator do
  include ValidatorHelpers

  let(:validator_test_class) { Size::Validator }
  let(:params) { {} }

  describe '#check_validity!' do
    include ChecksValidatorValidity
  end

  describe 'Validator checks' do
    let(:model) { validator_test_class::Check.new(params) }

    describe ':less_than' do
      # validates :less_than, size: { less_than: 2.kilobytes }
      # validates :less_than_proc, size: { less_than: -> (record) { 2.kilobytes } }
      %w(value proc).each do |value_type|
        describe "#{value_type} validator" do
          describe 'when provided with a lower size than the size specified in the model validations' do
            subject { model.less_than.attach(file_1ko) and model }

            it { is_expected_to_be_valid }
          end

          describe 'when provided with the exact size specified in the model validations' do
            subject { model.less_than.attach(file_2ko) and model }

            let(:error_options) do
              {
                file_size: '2 KB',
                filename: 'file_2ko',
                min_size: nil,
                max_size: '2 KB'
              }
            end

            it { is_expected_not_to_be_valid }
            it { is_expected_to_have_error_message("file_size_not_less_than", error_options: error_options) }
            it { is_expected_to_have_error_options(error_options) }
          end

          describe 'when provided with a higher size than the size specified in the model validations' do
            subject { model.less_than.attach(file_5ko) and model }

            let(:error_options) do
              {
                file_size: '5 KB',
                filename: 'file_5ko',
                min_size: nil,
                max_size: '2 KB'
              }
            end

            it { is_expected_not_to_be_valid }
            it { is_expected_to_have_error_message("file_size_not_less_than", error_options: error_options) }
            it { is_expected_to_have_error_options(error_options) }
          end
        end
      end
    end

    describe ':less_than_or_equal_to' do
      # validates :less_than_or_equal_to, size: { less_than_or_equal_to: 2.kilobytes }
      # validates :less_than_or_equal_to_proc, size: { less_than_or_equal_to: -> (record) { 2.kilobytes } }
      %w(value proc).each do |value_type|
        describe "#{value_type} validator" do
          describe 'when provided with a lower size than the size specified in the model validations' do
            subject { model.less_than_or_equal_to.attach(file_1ko) and model }

            it { is_expected_to_be_valid }
          end

          describe 'when provided with the exact size specified in the model validations' do
            subject { model.less_than_or_equal_to.attach(file_2ko) and model }

            it { is_expected_to_be_valid }
          end

          describe 'when provided with a higher size than the size specified in the model validations' do
            subject { model.less_than_or_equal_to.attach(file_5ko) and model }

            let(:error_options) do
              {
                file_size: '5 KB',
                filename: 'file_5ko',
                min_size: nil,
                max_size: '2 KB'
              }
            end

            it { is_expected_not_to_be_valid }
            it { is_expected_to_have_error_message("file_size_not_less_than_or_equal_to", error_options: error_options) }
            it { is_expected_to_have_error_options(error_options) }
          end
        end
      end
    end

    describe ':greater_than' do
      # validates :greater_than, size: { greater_than: 7.kilobytes }
      # validates :greater_than_proc, size: { greater_than: -> (record) { 7.kilobytes } }
      %w(value proc).each do |value_type|
        describe "#{value_type} validator" do
          describe 'when provided with a lower size than the size specified in the model validations' do
            subject { model.greater_than.attach(file_1ko) and model }

            let(:error_options) do
              {
                file_size: '1 KB',
                filename: 'file_1ko',
                min_size: '7 KB',
                max_size: nil
              }
            end

            it { is_expected_not_to_be_valid }
            it { is_expected_to_have_error_message("file_size_not_greater_than", error_options: error_options) }
            it { is_expected_to_have_error_options(error_options) }
          end

          describe 'when provided with the exact size specified in the model validations' do
            subject { model.greater_than.attach(file_7ko) and model }

            let(:error_options) do
              {
                file_size: '7 KB',
                filename: 'file_7ko',
                min_size: '7 KB',
                max_size: nil
              }
            end

            it { is_expected_not_to_be_valid }
            it { is_expected_to_have_error_message("file_size_not_greater_than", error_options: error_options) }
            it { is_expected_to_have_error_options(error_options) }
          end

          describe 'when provided with a higher size than the size specified in the model validations' do
            subject { model.greater_than.attach(file_10ko) and model }

            it { is_expected_to_be_valid }
          end
        end
      end
    end

    describe ':greater_than_or_equal_to' do
      # validates :greater_than_or_equal_to, size: { greater_than_or_equal_to: 7.kilobytes }
      # validates :greater_than_or_equal_to_proc, size: { greater_than_or_equal_to: -> (record) { 7.kilobytes } }
      %w(value proc).each do |value_type|
        describe "#{value_type} validator" do
          describe 'when provided with a lower size than the size specified in the model validations' do
            subject { model.greater_than_or_equal_to.attach(file_1ko) and model }

            let(:error_options) do
              {
                file_size: '1 KB',
                filename: 'file_1ko',
                min_size: '7 KB',
                max_size: nil
              }
            end

            it { is_expected_not_to_be_valid }
            it { is_expected_to_have_error_message("file_size_not_greater_than_or_equal_to", error_options: error_options) }
            it { is_expected_to_have_error_options(error_options) }
          end

          describe 'when provided with the exact size specified in the model validations' do
            subject { model.greater_than_or_equal_to.attach(file_7ko) and model }

            it { is_expected_to_be_valid }
          end

          describe 'when provided with a higher size than the size specified in the model validations' do
            subject { model.greater_than_or_equal_to.attach(file_10ko) and model }

            it { is_expected_to_be_valid }
          end
        end
      end
    end

    describe ':between' do
      # validates :between, size: { between: 2.kilobytes..7.kilobytes }
      # validates :between_proc, size: { between: -> (record) { 2.kilobytes..7.kilobytes } }
      %w(value proc).each do |value_type|
        describe "#{value_type} validator" do
          describe 'when provided with a lower size than the size specified in the model validations' do
            subject { model.between.attach(file_1ko) and model }

            let(:error_options) do
              {
                file_size: '1 KB',
                filename: 'file_1ko',
                min_size: '2 KB',
                max_size: '7 KB'
              }
            end

            it { is_expected_not_to_be_valid }
            it { is_expected_to_have_error_message("file_size_not_between", error_options: error_options) }
            it { is_expected_to_have_error_options(error_options) }
          end

          describe 'when provided with the exact lower size specified in the model validations' do
            subject { model.between.attach(file_2ko) and model }

            it { is_expected_to_be_valid }
          end

          describe 'when provided with a size between the sizes specified in the model validations' do
            subject { model.between.attach(file_5ko) and model }

            it { is_expected_to_be_valid }
          end

          describe 'when provided with the exact higher size specified in the model validations' do
            subject { model.between.attach(file_7ko) and model }

            it { is_expected_to_be_valid }
          end

          describe 'when provided with a higher size than the size specified in the model validations' do
            subject { model.between.attach(file_10ko) and model }

            let(:error_options) do
              {
                file_size: '10 KB',
                filename: 'file_10ko',
                min_size: '2 KB',
                max_size: '7 KB'
              }
            end

            it { is_expected_not_to_be_valid }
            it { is_expected_to_have_error_message("file_size_not_between", error_options: error_options) }
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
