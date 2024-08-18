# frozen_string_literal: true

require_relative 'concerns/active_storageable.rb'
require_relative 'concerns/allow_blankable.rb'
require_relative 'concerns/attachable'
require_relative 'concerns/contextable.rb'
require_relative 'concerns/messageable.rb'
require_relative 'concerns/rspecable.rb'
require_relative 'concerns/validatable.rb'

module ActiveStorageValidations
  module Matchers
    def validate_dimensions_of(name)
      DimensionValidatorMatcher.new(name)
    end

    class DimensionValidatorMatcher
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
        @number_file_min = @number_file_max = nil
      end

      def description
        "validate the limit files of :#{@attribute_name}"
      end

      def failure_message
        "is expected to validate limit file of :#{@attribute_name}"
      end

      def number_file(number)
        @number_file_min = @number_file_max = number
        self
      end

      def number_file_min(number)
        @number_file_min = number
        self
      end

      def number_file_max(number)
        @number_file_max = number
        self
      end

      def matches?(subject)
        @subject = subject.is_a?(Class) ? subject.new : subject

        is_a_valid_active_storage_attribute? &&
          is_context_valid? &&
          is_custom_message_valid? &&
          number_file_not_smaller_than_min? &&
          number_file_larger_than_min? &&
          number_file_smaller_than_max? &&
          number_file_not_larger_than_max?
      end

      private

      def build_failure_message(message)
        return unless @failure_message_artefacts.present?

        message << "  but there seem to have issues with the matcher methods you used, since:"
        @failure_message_artefacts.each do |error_case|
          message << "  validation failed when provided with a #{error_case[:width]}x#{error_case[:height]}px test image"
        end
        message << "  whereas it should have passed"
      end

      def number_file_not_smaller_than_min?
        @number_file_min.nil? || !passes_validation_with_dimensions(@number_file_min - 1, valid_height)
      end

      def number_file_larger_than_min?
        @number_file_min.nil? || @number_file_min == @number_file_max || passes_validation_with_dimensions(@number_file_min + 1, valid_height)
      end

      def number_file_smaller_than_max?
        @number_file_max.nil? || @number_file_min == @number_file_max || passes_validation_with_dimensions(@number_file_max - 1, valid_height)
      end

      def number_file_not_larger_than_max?
        @number_file_max.nil? || !passes_validation_with_dimensions(@number_file_max + 1, valid_height)
      end

      def passes_validation_with_dimensions(width, height)
        mock_dimensions_for(attach_file, width, height) do
          validate
          detach_file
          is_valid? || add_failure_message_artefact(width, height)
        end
      end

      def add_failure_message_artefact(width, height)
        @failure_message_artefacts << { width: width, height: height }
        false
      end

      def is_custom_message_valid?
        return true unless @custom_message

        mock_dimensions_for(attach_file, -1, -1) do
          validate
          detach_file
          has_an_error_message_which_is_custom_message?
        end
      end
    end
  end
end
