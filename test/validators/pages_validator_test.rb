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

describe ActiveStorageValidations::PagesValidator do
  include ValidatorHelpers

  let(:validator_test_class) { Pages::Validator }
  let(:params) { {} }

  describe "#check_validity!" do
    include ChecksValidatorValidity
  end

  describe "Validator checks" do
    include WorksFineWithAttachables

    let(:model) { validator_test_class::Check.new(params) }

    describe ":less_than" do
      let(:file_having_lower_than_less_than_option) { pdf_1_page_file }
      let(:file_having_exact_less_than_option) { pdf_2_pages_file }
      let(:file_having_higher_than_less_than_option) { pdf_5_pages_file }
      let(:error_name) { "pages_not_less_than" }
      let(:error_options_for_file_having_exact_less_than_option) do
        {
          pages: "2",
          filename: file_having_exact_less_than_option[:filename],
          min: nil,
          max: "2"
        }
      end
      let(:error_options_for_file_having_higher_than_less_than_option) do
        {
          pages: "5",
          filename: file_having_higher_than_less_than_option[:filename],
          min: nil,
          max: "2"
        }
      end

      include ComparisonLessThanOption
    end

    describe ":less_than_or_equal_to" do
      let(:file_having_lower_than_less_than_or_equal_to_option) { pdf_1_page_file }
      let(:file_having_exact_less_than_or_equal_to_option) { pdf_2_pages_file }
      let(:file_having_higher_than_less_than_or_equal_to_option) { pdf_5_pages_file }
      let(:error_name) { "pages_not_less_than_or_equal_to" }
      let(:error_options_for_file_having_exact_less_than_or_equal_to_option) do
        {
          pages: "2",
          filename: file_having_exact_less_than_or_equal_to_option[:filename],
          min: nil,
          max: "2"
        }
      end
      let(:error_options_for_file_having_higher_than_less_than_or_equal_to_option) do
        {
          pages: "5",
          filename: file_having_higher_than_less_than_or_equal_to_option[:filename],
          min: nil,
          max: "2"
        }
      end

      include ComparisonLessThanOrEqualToOption
    end

    describe ":greater_than" do
      let(:file_having_lower_than_greater_than_option) { pdf_1_page_file }
      let(:file_having_exact_greater_than_option) { pdf_7_pages_file }
      let(:file_having_higher_than_greater_than_option) { pdf_10_pages_file }
      let(:error_name) { "pages_not_greater_than" }
      let(:error_options_for_file_having_lower_than_greater_than_option) do
        {
          pages: "1",
          filename: file_having_lower_than_greater_than_option[:filename],
          min: "7",
          max: nil
        }
      end
      let(:error_options_for_file_having_exact_greater_than_option) do
        {
          pages: "7",
          filename: file_having_exact_greater_than_option[:filename],
          min: "7",
          max: nil
        }
      end

      include ComparisonGreaterThanOption
    end

    describe ":greater_than_or_equal_to" do
      let(:file_having_lower_than_greater_than_or_equal_to_option) { pdf_1_page_file }
      let(:file_having_exact_greater_than_or_equal_to_option) { pdf_7_pages_file }
      let(:file_having_higher_than_greater_than_or_equal_to_option) { pdf_10_pages_file }
      let(:error_name) { "pages_not_greater_than_or_equal_to" }
      let(:error_options_for_file_having_lower_than_greater_than_or_equal_to_option) do
        {
          pages: "1",
          filename: file_having_lower_than_greater_than_or_equal_to_option[:filename],
          min: "7",
          max: nil
        }
      end

      include ComparisonGreaterThanOrEqualToOption
    end

    describe ":between" do
      let(:file_having_lower_than_lower_bound_between_option) { pdf_1_page_file }
      let(:file_having_exact_lower_bound_between_option) { pdf_2_pages_file }
      let(:file_having_between_bounds_between_option) { pdf_5_pages_file }
      let(:file_having_exact_higher_bound_between_option) { pdf_7_pages_file }
      let(:file_having_higher_than_higher_bound_between_option) { pdf_10_pages_file }
      let(:error_name) { "pages_not_between" }
      let(:error_options_for_file_having_lower_than_lower_bound_between_option) do
        {
          pages: "1",
          filename: file_having_lower_than_lower_bound_between_option[:filename],
          min: "2",
          max: "7"
        }
      end
      let(:error_options_for_file_having_higher_than_higher_bound_between_option) do
        {
          pages: "10",
          filename: file_having_higher_than_higher_bound_between_option[:filename],
          min: "2",
          max: "7"
        }
      end

      include ComparisonBetweenOption
    end

    describe ":equal_to" do
      let(:file_having_lower_than_equal_to_option) { pdf_1_page_file }
      let(:file_having_exact_equal_to_option) { pdf_5_pages_file }
      let(:file_having_higher_than_equal_to_option) { pdf_7_pages_file }
      let(:error_name) { "pages_not_equal_to" }
      let(:error_options_for_file_having_lower_than_equal_to_option) do
        {
          pages: "1",
          filename: file_having_lower_than_equal_to_option[:filename],
          exact: "5"
        }
      end
      let(:error_options_for_file_having_higher_than_equal_to_option) do
        {
          pages: "7",
          filename: file_having_higher_than_equal_to_option[:filename],
          exact: "5"
        }
      end

      include ComparisonEqualToOption
    end
  end

  describe "Blob Metadata" do
    let(:attachable) do
      {
        io: File.open(Rails.root.join("public", "pdf_5_pages.pdf")),
        filename: "pdf_5_pages.pdf",
        content_type: "application/pdf"
      }
    end

    include IsPerformanceOptimized
  end

  describe "Rails options" do
    include WorksWithAllRailsCommonValidationOptions
  end
end
