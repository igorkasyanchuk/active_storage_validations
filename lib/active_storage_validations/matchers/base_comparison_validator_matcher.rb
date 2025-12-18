# frozen_string_literal: true

# Big thank you to the paperclip validation matchers:
# https://github.com/thoughtbot/paperclip/blob/v6.1.0/lib/paperclip/matchers/validate_attachment_size_matcher.rb

require_relative "shared/asv_active_storageable"
require_relative "shared/asv_allow_blankable"
require_relative "shared/asv_attachable"
require_relative "shared/asv_contextable"
require_relative "shared/asv_messageable"
require_relative "shared/asv_rspecable"
require_relative "shared/asv_validatable"

module ActiveStorageValidations
  module Matchers
    class BaseComparisonValidatorMatcher
      # BaseComparisonValidatorMatcher is an abstract class and shouldn't be instantiated directly.

      include ASVActiveStorageable
      include ASVAllowBlankable
      include ASVAttachable
      include ASVContextable
      include ASVMessageable
      include ASVRspecable
      include ASVValidatable

      def initialize(attribute_name)
        initialize_allow_blankable
        initialize_contextable
        initialize_messageable
        initialize_rspecable
        @attribute_name = attribute_name
        @min = @max = nil
      end

      def less_than(value)
        @max = value - smallest_measurement
        self
      end

      def less_than_or_equal_to(value)
        @max = value
        self
      end

      def greater_than(value)
        @min = value + smallest_measurement
        self
      end

      def greater_than_or_equal_to(value)
        @min = value
        self
      end

      def between(range)
        @min, @max = range.first, range.last
        self
      end

      def equal_to(value)
        @exact = value
        self
      end

      def matches?(subject)
        @subject = subject.is_a?(Class) ? subject.new : subject

        is_a_valid_active_storage_attribute? &&
          is_context_valid? &&
          is_allowing_blank? &&
          is_custom_message_valid? &&
          not_lower_than_min? &&
          higher_than_min? &&
          lower_than_max? &&
          not_higher_than_max? &&
          equal_to_exact?
      end

      protected

      def build_failure_message(message)
        return unless @failure_message_artefacts.present?

        message << "  but there seem to have issues with the matcher methods you used, since:"
        @failure_message_artefacts.each do |error_case|
          message << "  validation failed when provided with a #{error_case[:value]} #{failure_message_unit} test file"
        end
        message << "  whereas it should have passed"
      end

      def failure_message_unit
        raise NotImplementedError
      end

      def not_lower_than_min?
        @min.nil? || !passes_validation_with_value(@min - 1)
      end

      def higher_than_min?
        @min.nil? || passes_validation_with_value(@min + 1)
      end

      def lower_than_max?
        @max.nil? || @max == Float::INFINITY || passes_validation_with_value(@max - 1)
      end

      def not_higher_than_max?
        @max.nil? || @max == Float::INFINITY || !passes_validation_with_value(@max + 1)
      end

      def equal_to_exact?
        @exact.nil? || passes_validation_with_value(@exact)
      end

      def smallest_measurement
        raise NotImplementedError
      end

      def passes_validation_with_value(value)
        mock_value_for(io, value) do
          attach_file
          validate
          detach_file
          is_valid? || add_failure_message_artefact(value)
        end
      end

      def add_failure_message_artefact(value)
        @failure_message_artefacts << { value: value }
        false
      end

      def is_custom_message_valid?
        return true unless @custom_message

        mock_value_for(io, -smallest_measurement) do
          attach_file
          validate
          detach_file
          has_an_error_message_which_is_custom_message?
        end
      end

      def mock_value_for(io, size)
        raise NotImplementedError
      end
    end
  end
end
