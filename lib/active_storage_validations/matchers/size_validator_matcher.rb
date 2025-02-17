# frozen_string_literal: true

require_relative "base_comparison_validator_matcher"

module ActiveStorageValidations
  module Matchers
    def validate_size_of(attribute_name)
      SizeValidatorMatcher.new(attribute_name)
    end

    class SizeValidatorMatcher < BaseComparisonValidatorMatcher
      def description
        "validate file size of :#{@attribute_name}"
      end

      def failure_message
        message = [ "is expected to validate file size of :#{@attribute_name}" ]
        build_failure_message(message)
        message.join("\n")
      end

      private

      def failure_message_unit
        "bytes"
      end

      def smallest_measurement
        1.byte
      end

      def mock_value_for(io, size)
        Matchers.stub_method(io, :size, size) do
          yield
        end
      end
    end
  end
end
