# frozen_string_literal: true

require_relative "base_comparison_validator_matcher"
require_relative "shared/asv_timeoutable"

module ActiveStorageValidations
  module Matchers
    def validate_duration_of(attribute_name)
      DurationValidatorMatcher.new(attribute_name)
    end

    class DurationValidatorMatcher < BaseComparisonValidatorMatcher
      include ASVTimeoutable

      def initialize(attribute_name)
        super
        initialize_timeoutable
      end

      def base_description
        "validate file duration of :#{@attribute_name}"
      end

      def failure_message
        message = [ "is expected to validate file duration of :#{@attribute_name}" ]
        build_failure_message(message)
        message.join("\n")
      end

      private

      def describe_value(value)
        value.is_a?(ActiveSupport::Duration) ? value.inspect : "#{value} seconds"
      end

      def failure_message_unit
        "seconds"
      end

      # Analyzers round to milliseconds. A 1-second step made `less_than(1.second)`
      # probe duration 0, which DurationValidator treats as missing metadata.
      def smallest_measurement
        0.001.seconds
      end

      def lowest_comparable_value
        smallest_measurement
      end

      def mock_value_for(io, duration)
        Matchers.mock_metadata(io, { duration: duration }) do
          yield
        end
      end
    end
  end
end
