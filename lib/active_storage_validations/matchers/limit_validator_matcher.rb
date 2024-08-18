# frozen_string_literal: true
require 'pry'
require_relative 'concerns/active_storageable'
require_relative 'concerns/allow_blankable'
require_relative 'concerns/attachable'
require_relative 'concerns/contextable'
require_relative 'concerns/messageable'
require_relative 'concerns/rspecable'
require_relative 'concerns/validatable'

module ActiveStorageValidations
  module Matchers
    def validate_limits_of(name)
      LimitValidatorMatcher.new(name)
    end

    class LimitValidatorMatcher
      include ActiveStorageable
      include AllowBlankable
      include Attachable
      include Contextable
      include Messageable
      include Rspecable
      include Validatable

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
        message = ["is expected to validate limit file of :#{@attribute_name}"]
        build_failure_message(message)
        message.join("\n")
      end

      def min(number)
        @min = number
        self
      end

      def max(number)
        @max = number
        self
      end

      def matches?(subject)
        @subject = subject.is_a?(Class) ? subject.new : subject

        is_a_valid_active_storage_attribute? &&
          is_context_valid? &&
          is_custom_message_valid? &&
          file_number_not_smaller_than_min? &&
          file_number_equal_min? &&
          file_number_larger_than_min? &&
          file_number_smaller_than_max? &&
          file_number_equal_max? &&
          file_number_not_larger_than_max?
      end

        private

      def build_failure_message(message)
        return unless @failure_message_artefacts.present?

        message << "  but there seem to have issues with the matcher methods you used, since:"
        @failure_message_artefacts.each do |error_case|
          message << "  validation failed when provided with a #{error_case[:count]} file(s)"
        end
        message << "  whereas it should have passed"
      end

      def file_number_not_smaller_than_min?
        @min.nil? || @min.zero? || !passes_validation_with_limits(@min - 1)
      end

      def file_number_equal_min?
        @min.nil? || @min.zero? || passes_validation_with_limits(@min)
      end

      def file_number_larger_than_min?
        @min.nil? || @min.zero? || @min == @max || passes_validation_with_limits(@min + 1)
      end

      def file_number_smaller_than_max?
        @max.nil? || @min == @max || passes_validation_with_limits(@max - 1)
      end

      def file_number_equal_max?
        @max.nil? || passes_validation_with_limits(@max)
      end

      def file_number_not_larger_than_max?
        @max.nil? || !passes_validation_with_limits(@max + 1)
      end

      def passes_validation_with_limits(count)
        attach_files(count)
        validate
        detach_files
        is_valid? || add_failure_message_artefact(count)
      end

      def is_custom_message_valid?
        unless @min.nil?
          return true if @min.zero? && @max.nil?
        end

        return true unless @custom_message

        @min.nil? ? attach_files(@max + 1) : attach_files(@min - 1)
        validate
        detach_files
        has_an_error_message_which_is_custom_message?
      end

      def add_failure_message_artefact(count)
        @failure_message_artefacts << { count: count }
        false
      end

      def attach_files(count)
        return if count.negative? || count.zero?

        file_array = []
        (1..count).each do |i|
          dummy_file = {
            io: Tempfile.new('.'),
            filename: "dummy_#{i}.txt",
            content_type: 'text/plain'
          }
          file_array << dummy_file
        end

        @subject.public_send(@attribute_name).attach(file_array)
      end

      def detach_files
        @subject.attachment_changes.delete(@attribute_name.to_s)
      end
    end
  end
end
