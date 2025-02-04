# frozen_string_literal: true

require_relative "base_comparison_validator_matcher"

module ActiveStorageValidations
  module Matchers
    def validate_total_size_of(attribute_name)
      TotalSizeValidatorMatcher.new(attribute_name)
    end

    class TotalSizeValidatorMatcher < BaseComparisonValidatorMatcher
      def description
        "validate total file size of :#{@attribute_name}"
      end

      def failure_message
        message = [ "is expected to validate total file size of :#{@attribute_name}" ]
        build_failure_message(message)
        message.join("\n")
      end

      protected

      def attach_file
        # has_many_attached relation
        @subject.public_send(@attribute_name).attach([ dummy_blob ])
        @subject.public_send(@attribute_name)
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
