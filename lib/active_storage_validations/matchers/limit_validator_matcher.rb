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
        @file_number_min = @file_number_max = nil
      end

      def description
        "validate the limit files of :#{@attribute_name}"
      end

      def failure_message
        "is expected to validate limit file of :#{@attribute_name}"
      end

      def file_number(number)
        @file_number_min = @file_number_max = number
        self
      end

      def file_number_min(number)
        @file_number_min = number
        self
      end

      def file_number_max(number)
        @file_number_max = number
        self
      end

      def matches?(subject)
        @subject = subject.is_a?(Class) ? subject.new : subject

        is_a_valid_active_storage_attribute? &&
          is_context_valid? &&
          is_custom_message_valid? &&
          file_number_not_smaller_than_min? &&
          file_number_larger_than_min? &&
          file_number_equal_min? &&
          file_number_equal_max? &&
          file_number_smaller_than_max? &&
          file_number_not_larger_than_max?
      end

      private

      def build_failure_message(message)
        return unless @failure_message_artefacts.present?

        message << "  but there seem to have issues with the matcher methods you used, since:"
        @failure_message_artefacts.each do |error_case|
          message << "  validation failed when provided with a #{error_case[:limit]} files"
        end
        message << "  whereas it should have passed"
      end

      def file_number_not_smaller_than_min?
        @file_number_min.nil? || !passes_validation_with_limits(@file_number_min - 1)
      end

      def file_number_larger_than_min?
        @file_number_min.nil? || @file_number_min == @file_number_max || passes_validation_with_limits(@file_number_min + 1)
      end

      def file_number_equal_min?
        @file_number_min.nil? || !passes_validation_with_limits(@file_number_min)
      end

      def file_number_equal_max?
        @file_number_max.nil? || !passes_validation_with_limits(@file_number_min)
      end

      def file_number_smaller_than_max?
        @file_number_max.nil? || @file_number_min == @file_number_max || passes_validation_with_limits(@file_number_max - 1)
      end

      def file_number_not_larger_than_max?
        @file_number_max.nil? || !passes_validation_with_limits(@file_number_max + 1)
      end

      def passes_validation_with_limits(bound)
        mock_limits_for(bound) do
          validate
          detach_file
          is_valid?
        end
      end

      def is_custom_message_valid?
        return true unless @custom_message

        mock_limits_for(-1) do
          validate
          detach_file
          has_an_error_message_which_is_custom_message?
        end
      end

      def mock_limits_for(bound)
        dummy_file = {
          io: Tempfile.new('.'),
          filename: 'dummy.txt',
          content_type: 'text/plain'
        }

        bound.times do
          @subject.public_send(@attribute_name).attach(dummy_file)
        end
      end
    end
  end
end
