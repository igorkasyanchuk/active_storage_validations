# frozen_string_literal: true

require_relative "base_comparison_validator_matcher"

module ActiveStorageValidations
  module Matchers
    def validate_duration_of(attribute_name)
      DurationValidatorMatcher.new(attribute_name)
    end

    class DurationValidatorMatcher < BaseComparisonValidatorMatcher
      def description
        "validate file duration of :#{@attribute_name}"
      end

      def failure_message
        message = [ "is expected to validate file duration of :#{@attribute_name}" ]
        build_failure_message(message)
        message.join("\n")
      end

      private

      def failure_message_unit
        "seconds"
      end

      def smallest_measurement
        1.second
      end

      def mock_value_for(io, duration)
        Matchers.mock_metadata(io, { duration: duration }) do
          yield
        end
      end
    end
  end
end
