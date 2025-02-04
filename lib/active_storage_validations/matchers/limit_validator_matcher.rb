# frozen_string_literal: true

require_relative "shared/asv_active_storageable"
require_relative "shared/asv_allow_blankable"
require_relative "shared/asv_attachable"
require_relative "shared/asv_contextable"
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

      def description
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
        @subject = subject.is_a?(Class) ? subject.new : subject

        is_a_valid_active_storage_attribute? &&
          is_context_valid? &&
          is_custom_message_valid? &&
          file_count_not_smaller_than_min? &&
          file_count_equal_min? &&
          file_count_larger_than_min? &&
          file_count_smaller_than_max? &&
          file_count_equal_max? &&
          file_count_not_larger_than_max?
      end

        private

      def build_failure_message(message)
        return unless @failure_message_artefacts.present?

        message << "  but there seem to have issues with the matcher methods you used, since:"
        @failure_message_artefacts.each do |error_case|
          message << "  validation failed when provided with #{error_case[:count]} file(s)"
        end
        message << "  whereas it should have passed"
      end

      def file_count_not_smaller_than_min?
        @min.nil? || @min.zero? || !passes_validation_with_limits(@min - 1)
      end

      def file_count_equal_min?
        @min.nil? || @min.zero? || passes_validation_with_limits(@min)
      end

      def file_count_larger_than_min?
        @min.nil? || @min.zero? || @min == @max || passes_validation_with_limits(@min + 1)
      end

      def file_count_smaller_than_max?
        @max.nil? || @min == @max || passes_validation_with_limits(@max - 1)
      end

      def file_count_equal_max?
        @max.nil? || passes_validation_with_limits(@max)
      end

      def file_count_not_larger_than_max?
        @max.nil? || !passes_validation_with_limits(@max + 1)
      end

      def passes_validation_with_limits(count)
        attach_files(count)
        validate
        detach_files
        is_valid? || add_failure_message_artefact(count)
      end

      def is_custom_message_valid?
        return true if !@custom_message || (@min&.zero? && @max.nil?)

        @min.nil? ? attach_files(@max + 1) : attach_files(@min - 1)
        validate
        detach_files
        has_an_error_message_which_is_custom_message?
      end

      def add_failure_message_artefact(count)
        @failure_message_artefacts << { count: count }
        false
      end
    end
  end
end
