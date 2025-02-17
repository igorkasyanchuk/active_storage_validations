# frozen_string_literal: true

require "test_helper"
require "validators/shared_examples/checks_validator_validity"
require "validators/shared_examples/works_with_all_rails_common_validation_options"

describe ActiveStorageValidations::TotalSizeValidator do
  include ValidatorHelpers

  let(:validator_test_class) { TotalSize::Validator }
  let(:params) { {} }

  describe "#(custom_)check_validity!" do
    include ChecksValidatorValidity

    describe "when used with has_one_attached" do
      subject { instance.invalid.attach(blob_file_1ko) and instance }

      let(:instance) { validator_test_class::CheckValidityHasManyAttachedOnly.new(params) }

      it "raises an error at model initialization" do
        assert_raises(ArgumentError, "This validator is only available for has_many_attached relations") { subject.valid? }
      end
    end
  end

  describe "Validator checks" do
    let(:model) { validator_test_class::Check.new(params) }

    describe ":less_than" do
      # validates :less_than, total_size: { less_than: 2.kilobytes }
      # validates :less_than_proc, total_size: { less_than: -> (record) { 2.kilobytes } }
      %w[value proc].each do |value_type|
        describe "#{value_type} validator" do
          describe "when provided with a lower total_size than the total_size specified in the model validations" do
            subject { model.less_than.attach([ blob_file_0_5ko, blob_file_0_5ko ]) and model }

            it { is_expected_to_be_valid }
          end

          describe "when provided with the exact total_size specified in the model validations" do
            subject { model.less_than.attach([ blob_file_1ko, blob_file_1ko ]) and model }

            let(:error_options) do
              {
                total_file_size: "2 KB",
                min: nil,
                max: "2 KB"
              }
            end

            it { is_expected_not_to_be_valid }
            it { is_expected_to_include_error_message("total_file_size_not_less_than", error_options: error_options) }
            it { is_expected_to_have_error_options(error_options) }
          end

          describe "when provided with a higher total_size than the total_size specified in the model validations" do
            subject { model.less_than.attach([ blob_file_5ko, blob_file_5ko ]) and model }

            let(:error_options) do
              {
                total_file_size: "10 KB",
                min: nil,
                max: "2 KB"
              }
            end

            it { is_expected_not_to_be_valid }
            it { is_expected_to_include_error_message("total_file_size_not_less_than", error_options: error_options) }
            it { is_expected_to_have_error_options(error_options) }
          end
        end
      end
    end

    describe ":less_than_or_equal_to" do
      # validates :less_than_or_equal_to, total_size: { less_than_or_equal_to: 2.kilobytes }
      # validates :less_than_or_equal_to_proc, total_size: { less_than_or_equal_to: -> (record) { 2.kilobytes } }
      %w[value proc].each do |value_type|
        describe "#{value_type} validator" do
          describe "when provided with a lower total_size than the total_size specified in the model validations" do
            subject { model.less_than_or_equal_to.attach([ blob_file_0_5ko, blob_file_0_5ko ]) and model }

            it { is_expected_to_be_valid }
          end

          describe "when provided with the exact total_size specified in the model validations" do
            subject { model.less_than_or_equal_to.attach([ blob_file_1ko, blob_file_1ko ]) and model }

            it { is_expected_to_be_valid }
          end

          describe "when provided with a higher total_size than the total_size specified in the model validations" do
            subject { model.less_than_or_equal_to.attach([ blob_file_1ko, blob_file_5ko ]) and model }

            let(:error_options) do
              {
                total_file_size: "6 KB",
                min: nil,
                max: "2 KB"
              }
            end

            it { is_expected_not_to_be_valid }
            it { is_expected_to_include_error_message("total_file_size_not_less_than_or_equal_to", error_options: error_options) }
            it { is_expected_to_have_error_options(error_options) }
          end
        end
      end
    end

    describe ":greater_than" do
      # validates :greater_than, total_size: { greater_than: 7.kilobytes }
      # validates :greater_than_proc, total_size: { greater_than: -> (record) { 7.kilobytes } }
      %w[value proc].each do |value_type|
        describe "#{value_type} validator" do
          describe "when provided with a lower total_size than the total_size specified in the model validations" do
            subject { model.greater_than.attach([ blob_file_1ko, blob_file_1ko ]) and model }

            let(:error_options) do
              {
                total_file_size: "2 KB",
                min: "7 KB",
                max: nil
              }
            end

            it { is_expected_not_to_be_valid }
            it { is_expected_to_include_error_message("total_file_size_not_greater_than", error_options: error_options) }
            it { is_expected_to_have_error_options(error_options) }
          end

          describe "when provided with the exact total_size specified in the model validations" do
            subject { model.greater_than.attach([ blob_file_5ko, blob_file_2ko ]) and model }

            let(:error_options) do
              {
                total_file_size: "7 KB",
                min: "7 KB",
                max: nil
              }
            end

            it { is_expected_not_to_be_valid }
            it { is_expected_to_include_error_message("total_file_size_not_greater_than", error_options: error_options) }
            it { is_expected_to_have_error_options(error_options) }
          end

          describe "when provided with a higher total_size than the total_size specified in the model validations" do
            subject { model.greater_than.attach([ blob_file_5ko, blob_file_5ko ]) and model }

            it { is_expected_to_be_valid }
          end
        end
      end
    end

    describe ":greater_than_or_equal_to" do
      # validates :greater_than_or_equal_to, total_size: { greater_than_or_equal_to: 7.kilobytes }
      # validates :greater_than_or_equal_to_proc, total_size: { greater_than_or_equal_to: -> (record) { 7.kilobytes } }
      %w[value proc].each do |value_type|
        describe "#{value_type} validator" do
          describe "when provided with a lower total_size than the total_size specified in the model validations" do
            subject { model.greater_than_or_equal_to.attach([ blob_file_1ko, blob_file_1ko ]) and model }

            let(:error_options) do
              {
                total_file_size: "2 KB",
                min: "7 KB",
                max: nil
              }
            end

            it { is_expected_not_to_be_valid }
            it { is_expected_to_include_error_message("total_file_size_not_greater_than_or_equal_to", error_options: error_options) }
            it { is_expected_to_have_error_options(error_options) }
          end

          describe "when provided with the exact total_size specified in the model validations" do
            subject { model.greater_than_or_equal_to.attach([ blob_file_5ko, blob_file_2ko ]) and model }

            it { is_expected_to_be_valid }
          end

          describe "when provided with a higher total_size than the total_size specified in the model validations" do
            subject { model.greater_than_or_equal_to.attach([ blob_file_5ko, blob_file_5ko ]) and model }

            it { is_expected_to_be_valid }
          end
        end
      end
    end

    describe ":between" do
      # validates :between, total_size: { between: 2.kilobytes..7.kilobytes }
      # validates :between_proc, total_size: { between: -> (record) { 2.kilobytes..7.kilobytes } }
      %w[value proc].each do |value_type|
        describe "#{value_type} validator" do
          describe "when provided with a lower total_size than the total_size specified in the model validations" do
            subject { model.between.attach([ blob_file_1ko, blob_file_0_5ko ]) and model }

            let(:error_options) do
              {
                total_file_size: "1.5 KB",
                min: "2 KB",
                max: "7 KB"
              }
            end

            it { is_expected_not_to_be_valid }
            it { is_expected_to_include_error_message("total_file_size_not_between", error_options: error_options) }
            it { is_expected_to_have_error_options(error_options) }
          end

          describe "when provided with the exact lower total_size specified in the model validations" do
            subject { model.between.attach([ blob_file_1ko, blob_file_1ko ]) and model }

            it { is_expected_to_be_valid }
          end

          describe "when provided with a total_size between the total_sizes specified in the model validations" do
            subject { model.between.attach([ blob_file_2ko, blob_file_1ko ]) and model }

            it { is_expected_to_be_valid }
          end

          describe "when provided with the exact higher total_size specified in the model validations" do
            subject { model.between.attach([ blob_file_5ko, blob_file_2ko ]) and model }

            it { is_expected_to_be_valid }
          end

          describe "when provided with a higher total_size than the total_size specified in the model validations" do
            subject { model.between.attach([ blob_file_5ko, blob_file_5ko ]) and model }

            let(:error_options) do
              {
                total_file_size: "10 KB",
                min: "2 KB",
                max: "7 KB"
              }
            end

            it { is_expected_not_to_be_valid }
            it { is_expected_to_include_error_message("total_file_size_not_between", error_options: error_options) }
            it { is_expected_to_have_error_options(error_options) }
          end
        end
      end
    end
  end

  describe "Rails options" do
    include WorksWithAllRailsCommonValidationOptions
  end
end
