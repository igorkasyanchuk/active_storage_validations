# frozen_string_literal: true

require "test_helper"
require "validators/shared_examples/checks_validator_validity"
require "validators/shared_examples/comparison_less_than_option"
require "validators/shared_examples/comparison_less_than_or_equal_to_option"
require "validators/shared_examples/comparison_greater_than_option"
require "validators/shared_examples/comparison_greater_than_or_equal_to_option"
require "validators/shared_examples/comparison_between_option"
require "validators/shared_examples/comparison_equal_to_option"
require "validators/shared_examples/is_performance_optimized"
require "validators/shared_examples/works_fine_with_attachables"
require "validators/shared_examples/works_with_all_rails_common_validation_options"

describe ActiveStorageValidations::SizeValidator do
  include ValidatorHelpers

  let(:validator_test_class) { Size::Validator }
  let(:params) { {} }

  describe "#check_validity!" do
    include ChecksValidatorValidity
  end

  describe "Validator checks" do
    let(:model) { validator_test_class::Check.new(params) }

    describe ":less_than" do
      let(:file_having_lower_than_less_than_option) { file_1ko }
      let(:file_having_exact_less_than_option) { file_2ko }
      let(:file_having_higher_than_less_than_option) { file_5ko }
      let(:error_name) { "file_size_not_less_than" }
      let(:error_options_for_file_having_exact_less_than_option) do
        {
          file_size: "2 KB",
          filename: file_having_exact_less_than_option[:filename],
          min: nil,
          max: "2 KB"
        }
      end
      let(:error_options_for_file_having_higher_than_less_than_option) do
        {
          file_size: "5 KB",
          filename: file_having_higher_than_less_than_option[:filename],
          min: nil,
          max: "2 KB"
        }
      end

      include ComparisonLessThanOption
    end

    describe ":less_than_or_equal_to" do
      let(:file_having_lower_than_less_than_or_equal_to_option) { file_1ko }
      let(:file_having_exact_less_than_or_equal_to_option) { file_2ko }
      let(:file_having_higher_than_less_than_or_equal_to_option) { file_5ko }
      let(:error_name) { "file_size_not_less_than_or_equal_to" }
      let(:error_options_for_file_having_exact_less_than_or_equal_to_option) do
        {
          file_size: "2 KB",
          filename: file_having_exact_less_than_or_equal_to_option[:filename],
          min: nil,
          max: "2 KB"
        }
      end
      let(:error_options_for_file_having_higher_than_less_than_or_equal_to_option) do
        {
          file_size: "5 KB",
          filename: file_having_higher_than_less_than_or_equal_to_option[:filename],
          min: nil,
          max: "2 KB"
        }
      end

      include ComparisonLessThanOrEqualToOption
    end

    describe ":greater_than" do
      let(:file_having_lower_than_greater_than_option) { file_1ko }
      let(:file_having_exact_greater_than_option) { file_7ko }
      let(:file_having_higher_than_greater_than_option) { file_10ko }
      let(:error_name) { "file_size_not_greater_than" }
      let(:error_options_for_file_having_lower_than_greater_than_option) do
        {
          file_size: "1 KB",
          filename: file_having_lower_than_greater_than_option[:filename],
          min: "7 KB",
          max: nil
        }
      end
      let(:error_options_for_file_having_exact_greater_than_option) do
        {
          file_size: "7 KB",
          filename: file_having_exact_greater_than_option[:filename],
          min: "7 KB",
          max: nil
        }
      end

      include ComparisonGreaterThanOption
    end

    describe ":greater_than_or_equal_to" do
      let(:file_having_lower_than_greater_than_or_equal_to_option) { file_1ko }
      let(:file_having_exact_greater_than_or_equal_to_option) { file_7ko }
      let(:file_having_higher_than_greater_than_or_equal_to_option) { file_10ko }
      let(:error_name) { "file_size_not_greater_than_or_equal_to" }
      let(:error_options_for_file_having_lower_than_greater_than_or_equal_to_option) do
        {
          file_size: "1 KB",
          filename: file_having_lower_than_greater_than_or_equal_to_option[:filename],
          min: "7 KB",
          max: nil
        }
      end

      include ComparisonGreaterThanOrEqualToOption
    end

    describe ":between" do
      let(:file_having_lower_than_lower_bound_between_option) { file_1ko }
      let(:file_having_exact_lower_bound_between_option) { file_2ko }
      let(:file_having_between_bounds_between_option) { file_5ko }
      let(:file_having_exact_higher_bound_between_option) { file_7ko }
      let(:file_having_higher_than_higher_bound_between_option) { file_10ko }
      let(:error_name) { "file_size_not_between" }
      let(:error_options_for_file_having_lower_than_lower_bound_between_option) do
        {
          file_size: "1 KB",
          filename: file_having_lower_than_lower_bound_between_option[:filename],
          min: "2 KB",
          max: "7 KB"
        }
      end
      let(:error_options_for_file_having_higher_than_higher_bound_between_option) do
        {
          file_size: "10.2 KB",
          filename: file_having_higher_than_higher_bound_between_option[:filename],
          min: "2 KB",
          max: "7 KB"
        }
      end

      include ComparisonBetweenOption
    end

    describe ":equal_to" do
      let(:file_having_lower_than_equal_to_option) { file_1ko }
      let(:file_having_exact_equal_to_option) { file_5ko }
      let(:file_having_higher_than_equal_to_option) { file_7ko }
      let(:error_name) { "file_size_not_equal_to" }
      let(:error_options_for_file_having_lower_than_equal_to_option) do
        {
          file_size: "1 KB",
          filename: file_having_lower_than_equal_to_option[:filename],
          exact: "5 KB"
        }
      end
      let(:error_options_for_file_having_higher_than_equal_to_option) do
        {
          file_size: "7 KB",
          filename: file_having_higher_than_equal_to_option[:filename],
          exact: "5 KB"
        }
      end

      include ComparisonEqualToOption
    end
  end

  describe "Rails options" do
    include WorksWithAllRailsCommonValidationOptions
  end
end
