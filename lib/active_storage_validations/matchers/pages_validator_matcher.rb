# frozen_string_literal: true

require_relative "base_comparison_validator_matcher"

module ActiveStorageValidations
  module Matchers
    def validate_pages_of(attribute_name)
      PagesValidatorMatcher.new(attribute_name)
    end

    class PagesValidatorMatcher < BaseComparisonValidatorMatcher
      def description
        "validate file number of pages of :#{@attribute_name}"
      end

      def failure_message
        message = [ "is expected to validate file number of pages of :#{@attribute_name}" ]
        build_failure_message(message)
        message.join("\n")
      end

      private

      def failure_message_unit
        "pages"
      end

      def smallest_measurement
        1
      end

      def mock_value_for(io, pages)
        Matchers.mock_metadata(io, { pages: pages }) do
          yield
        end
      end
    end
  end
end
