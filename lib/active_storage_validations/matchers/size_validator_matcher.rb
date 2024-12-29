# frozen_string_literal: true

require_relative 'base_comparison_validator_matcher'

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
        message = ["is expected to validate file size of :#{@attribute_name}"]
        build_failure_message(message)
        message.join("\n")
      end
    end
  end
end
