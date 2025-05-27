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

describe ActiveStorageValidations::DurationValidator do
  include ValidatorHelpers

  let(:validator_test_class) { Duration::Validator }
  let(:params) { {} }

  describe "#check_validity!" do
    include ChecksValidatorValidity
  end

  describe "Validator checks" do
    include WorksFineWithAttachables

    let(:model) { validator_test_class::Check.new(params) }

    describe ":less_than" do
      let(:file_having_lower_than_less_than_option) { audio_1s }
      let(:file_having_exact_less_than_option) { audio_2s }
      let(:file_having_higher_than_less_than_option) { audio_5s }
      let(:error_name) { "duration_not_less_than" }
      let(:error_options_for_file_having_exact_less_than_option) do
        {
          duration: "2 seconds",
          filename: file_having_exact_less_than_option[:filename],
          min: nil,
          max: "2 seconds"
        }
      end
      let(:error_options_for_file_having_higher_than_less_than_option) do
        {
          duration: "5 seconds",
          filename: file_having_higher_than_less_than_option[:filename],
          min: nil,
          max: "2 seconds"
        }
      end

      include ComparisonLessThanOption
    end

    describe ":less_than_or_equal_to" do
      let(:file_having_lower_than_less_than_or_equal_to_option) { audio_1s }
      let(:file_having_exact_less_than_or_equal_to_option) { audio_2s }
      let(:file_having_higher_than_less_than_or_equal_to_option) { audio_5s }
      let(:error_name) { "duration_not_less_than_or_equal_to" }
      let(:error_options_for_file_having_exact_less_than_or_equal_to_option) do
        {
          duration: "2 seconds",
          filename: file_having_exact_less_than_or_equal_to_option[:filename],
          min: nil,
          max: "2 seconds"
        }
      end
      let(:error_options_for_file_having_higher_than_less_than_or_equal_to_option) do
        {
          duration: "5 seconds",
          filename: file_having_higher_than_less_than_or_equal_to_option[:filename],
          min: nil,
          max: "2 seconds"
        }
      end

      include ComparisonLessThanOrEqualToOption
    end

    describe ":greater_than" do
      let(:file_having_lower_than_greater_than_option) { audio_1s }
      let(:file_having_exact_greater_than_option) { audio_7s }
      let(:file_having_higher_than_greater_than_option) { audio_10s }
      let(:error_name) { "duration_not_greater_than" }
      let(:error_options_for_file_having_lower_than_greater_than_option) do
        {
          duration: "1 second",
          filename: file_having_lower_than_greater_than_option[:filename],
          min: "7 seconds",
          max: nil
        }
      end
      let(:error_options_for_file_having_exact_greater_than_option) do
        {
          duration: "7 seconds",
          filename: file_having_exact_greater_than_option[:filename],
          min: "7 seconds",
          max: nil
        }
      end

      include ComparisonGreaterThanOption
    end

    describe ":greater_than_or_equal_to" do
      let(:file_having_lower_than_greater_than_or_equal_to_option) { audio_1s }
      let(:file_having_exact_greater_than_or_equal_to_option) { audio_7s }
      let(:file_having_higher_than_greater_than_or_equal_to_option) { audio_10s }
      let(:error_name) { "duration_not_greater_than_or_equal_to" }
      let(:error_options_for_file_having_lower_than_greater_than_or_equal_to_option) do
        {
          duration: "1 second",
          filename: file_having_lower_than_greater_than_or_equal_to_option[:filename],
          min: "7 seconds",
          max: nil
        }
      end

      include ComparisonGreaterThanOrEqualToOption
    end

    describe ":between" do
      let(:file_having_lower_than_lower_bound_between_option) { audio_1s }
      let(:file_having_exact_lower_bound_between_option) { audio_2s }
      let(:file_having_between_bounds_between_option) { audio_5s }
      let(:file_having_exact_higher_bound_between_option) { audio_7s }
      let(:file_having_higher_than_higher_bound_between_option) { audio_10s }
      let(:error_name) { "duration_not_between" }
      let(:error_options_for_file_having_lower_than_lower_bound_between_option) do
        {
          duration: "1 second",
          filename: file_having_lower_than_lower_bound_between_option[:filename],
          min: "2 seconds",
          max: "7 seconds"
        }
      end
      let(:error_options_for_file_having_higher_than_higher_bound_between_option) do
        {
          duration: "10 seconds",
          filename: file_having_higher_than_higher_bound_between_option[:filename],
          min: "2 seconds",
          max: "7 seconds"
        }
      end

      include ComparisonBetweenOption
    end

    describe ":equal_to" do
      let(:file_having_lower_than_equal_to_option) { audio_2s }
      let(:file_having_exact_equal_to_option) { audio_5s }
      let(:file_having_higher_than_equal_to_option) { audio_7s }
      let(:error_name) { "duration_not_equal_to" }
      let(:error_options_for_file_having_lower_than_equal_to_option) do
        {
          duration: "2 seconds",
          filename: file_having_lower_than_equal_to_option[:filename],
          exact: "5 seconds"
        }
      end
      let(:error_options_for_file_having_higher_than_equal_to_option) do
        {
          duration: "7 seconds",
          filename: file_having_higher_than_equal_to_option[:filename],
          exact: "5 seconds"
        }
      end

      include ComparisonEqualToOption
    end
  end

  describe "Blob Metadata" do
    let(:attachable) do
      {
        io: File.open(Rails.root.join("public", "audio.mp3")),
        filename: "audio.mp3",
        content_type: "audio/mp3"
      }
    end

    include IsPerformanceOptimized
  end

  describe "Rails options" do
    include WorksWithAllRailsCommonValidationOptions
  end
end
