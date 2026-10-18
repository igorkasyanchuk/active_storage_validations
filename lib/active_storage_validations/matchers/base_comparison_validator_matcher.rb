# frozen_string_literal: true

# Big thank you to the paperclip validation matchers:
# https://github.com/thoughtbot/paperclip/blob/v6.1.0/lib/paperclip/matchers/validate_attachment_size_matcher.rb

require_relative "shared/asv_active_storageable"
require_relative "shared/asv_allow_blankable"
require_relative "shared/asv_attachable"
require_relative "shared/asv_contextable"
require_relative "shared/asv_except_onable"
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
      include ASVExceptOnable
      include ASVMessageable
      include ASVRspecable
      include ASVValidatable

      def initialize(attribute_name)
        initialize_allow_blankable
        initialize_contextable
        initialize_except_onable
        initialize_messageable
        initialize_rspecable
        @attribute_name = attribute_name
        @min = @max = @exact = nil
        @chain_descriptions = {}
      end

      def less_than(value)
        @max = value - smallest_measurement
        @chain_descriptions[:less_than] = "less than #{describe_value(value)}"
        self
      end

      def less_than_or_equal_to(value)
        @max = value
        @chain_descriptions[:less_than_or_equal_to] = "less than or equal to #{describe_value(value)}"
        self
      end

      def greater_than(value)
        @min = value + smallest_measurement
        @chain_descriptions[:greater_than] = "greater than #{describe_value(value)}"
        self
      end

      def greater_than_or_equal_to(value)
        @min = value
        @chain_descriptions[:greater_than_or_equal_to] = "greater than or equal to #{describe_value(value)}"
        self
      end

      def between(range)
        @min = range.begin
        @max = last_included_bound(range)
        @chain_descriptions[:between] = "between #{describe_value(range.begin)} and #{describe_value(range.end)}#{" (excluded)" if range.exclude_end?}"
        self
      end

      def equal_to(value)
        @exact = value
        @chain_descriptions[:equal_to] = "equal to #{describe_value(value)}"
        self
      end

      def matches?(subject)
        initialize_subject(subject)

        is_a_valid_active_storage_attribute? &&
          has_validator? &&
          is_context_valid? &&
          is_except_on_valid? &&
          is_allowing_blank? &&
          is_custom_message_valid? &&
          not_lower_than_min? &&
          higher_than_min? &&
          lower_than_max? &&
          not_higher_than_max? &&
          equal_to_exact? &&
          is_timeout_valid?
      end

      protected

      # Hook for ASVTimeoutable (Duration / Pages). Size / TotalSize leave this as-is.
      def is_timeout_valid?
        true
      end

      def chain_descriptions
        @chain_descriptions.values
      end

      def describe_value(value)
        raise NotImplementedError
      end

      def failure_message_unit
        raise NotImplementedError
      end

      def not_lower_than_min?
        @min.nil? || rejects_value?(@min - smallest_measurement)
      end

      # Probe the inclusive bound itself. Checking only min+1 / max-1 lets
      # less_than(n) satisfy less_than_or_equal_to(n) (and greater_than
      # satisfy greater_than_or_equal_to). Duration / pages treat 0 as
      # media_metadata_missing, so probe the first comparable value instead.
      def higher_than_min?
        return true if @min.nil?
        return false unless accepts_value?(probeable_value(@min))

        !unprobeable_zero_min? || validator_declares_zero_lower_bound?
      end

      def lower_than_max?
        @max.nil? || @max == Float::INFINITY || accepts_value?(@max)
      end

      def not_higher_than_max?
        @max.nil? || @max == Float::INFINITY || rejects_value?(@max + smallest_measurement)
      end

      def equal_to_exact?
        return true if @exact.nil?

        if zero_like?(@exact) && @exact < lowest_comparable_value
          zero_like?(attribute_validator&.options&.[](:equal_to))
        else
          accepts_value?(@exact) &&
            rejects_value?(@exact - smallest_measurement) &&
            rejects_value?(@exact + smallest_measurement)
        end
      end

      def smallest_measurement
        raise NotImplementedError
      end

      # Size / total_size can probe 0 bytes. Duration / pages override: 0 is
      # media_metadata_missing rather than an in-range comparison.
      def lowest_comparable_value
        0
      end

      def probeable_value(value)
        lowest = lowest_comparable_value
        value < lowest ? lowest : value
      end

      def zero_like?(value)
        value.respond_to?(:zero?) && value.zero?
      end

      def unprobeable_zero_min?
        zero_like?(@min) && @min < lowest_comparable_value
      end

      def validator_declares_zero_lower_bound?
        options = attribute_validator&.options || {}
        zero_like?(options[:greater_than_or_equal_to]) ||
          (options[:between].is_a?(Range) && zero_like?(options[:between].begin))
      end

      # Exclusive ranges (`1...5`) reject the end bound. Probe the last included
      # value so `#between(80...100)` does not match an inclusive `80..100`.
      def last_included_bound(range)
        return range.end unless range.exclude_end?

        range.end - smallest_measurement
      end

      def accepts_value?(value)
        passes_validation_with_value(value) || add_failure_message_artefact(probe_description(value), passed: false)
      end

      def rejects_value?(value)
        !passes_validation_with_value(value) || add_failure_message_artefact(probe_description(value), passed: true)
      end

      def probe_description(value)
        "a #{value} #{failure_message_unit} test file"
      end

      def passes_validation_with_value(value)
        mock_value_for(io, value) do
          attach_file
          validate
          detach_file
          is_valid?
        end
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
