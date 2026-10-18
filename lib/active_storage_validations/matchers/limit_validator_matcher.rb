# frozen_string_literal: true

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
    def validate_limits_of(name)
      LimitValidatorMatcher.new(name)
    end

    class LimitValidatorMatcher
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
        @min = @max = nil
      end

      def base_description
        "validate the limit files of :#{@attribute_name}"
      end

      def failure_message
        message = [ "is expected to validate limit file of :#{@attribute_name}" ]
        build_failure_message(message)
        message.join("\n")
      end

      def min(count)
        @min = count
        self
      end

      def max(count)
        @max = count
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
          file_count_not_smaller_than_min? &&
          file_count_equal_min? &&
          file_count_larger_than_min? &&
          file_count_smaller_than_max? &&
          file_count_equal_max? &&
          file_count_not_larger_than_max?
      end

      private

      def chain_descriptions
        [
          ("at least #{describe_count(@min)}" if @min),
          ("at most #{describe_count(@max)}" if @max)
        ].compact
      end

      def describe_count(count)
        "#{count} #{"file".pluralize(count)}"
      end

      def file_count_not_smaller_than_min?
        @min.nil? || @min.zero? || (@allow_blank && @min == 1) || rejects_count?(@min - 1)
      end

      def file_count_equal_min?
        return true if @min.nil?
        return false unless accepts_count?(@min)

        !@min.zero? || validator_min_zero?
      end

      def file_count_larger_than_min?
        @min.nil? || @min == @max || accepts_count?(@min + 1)
      end

      def validator_min_zero?
        attribute_validator&.options&.[](:min) == 0
      end

      def file_count_smaller_than_max?
        @max.nil? || @min == @max || accepts_count?(@max - 1)
      end

      def file_count_equal_max?
        @max.nil? || accepts_count?(@max)
      end

      def file_count_not_larger_than_max?
        @max.nil? || rejects_count?(@max + 1)
      end

      def accepts_count?(count)
        passes_validation_with_limits(count) || add_failure_message_artefact("#{count} file(s)", passed: false)
      end

      def rejects_count?(count)
        !passes_validation_with_limits(count) || add_failure_message_artefact("#{count} file(s)", passed: true)
      end

      def passes_validation_with_limits(count)
        attach_files(count)
        validate
        detach_files
        is_valid?
      end

      def is_custom_message_valid?
        return true if !@custom_message || (@min&.zero? && @max.nil?)
        raise ArgumentError, "#with_message needs #min or #max to build a file count the validator rejects" if @min.nil? && @max.nil?

        attach_files(@min.nil? || @min.zero? ? @max + 1 : @min - 1)
        validate
        detach_files
        has_an_error_message_which_is_custom_message?
      end
    end
  end
end
