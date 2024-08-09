# frozen_string_literal: true

# Big thank you to the paperclip validation matchers:
# https://github.com/thoughtbot/paperclip/blob/v6.1.0/lib/paperclip/matchers/validate_attachment_size_matcher.rb

require_relative 'concerns/active_storageable.rb'
require_relative 'concerns/allow_blankable.rb'
require_relative 'concerns/attachable.rb'
require_relative 'concerns/contextable.rb'
require_relative 'concerns/messageable.rb'
require_relative 'concerns/rspecable.rb'
require_relative 'concerns/validatable.rb'

module ActiveStorageValidations
  module Matchers
    class BaseSizeValidatorMatcher
      # BaseSizeValidatorMatcher is an abstract class and shouldn't be instantiated directly.

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

      def less_than(size)
        @max = size - 1.byte
        self
      end

      def less_than_or_equal_to(size)
        @max = size
        self
      end

      def greater_than(size)
        @min = size + 1.byte
        self
      end

      def greater_than_or_equal_to(size)
        @min = size
        self
      end

      def between(range)
        @min, @max = range.first, range.last
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
          not_higher_than_max?
      end

      protected

      def build_failure_message(message)
        return unless @failure_message_artefacts.present?

        message << "  but there seem to have issues with the matcher methods you used, since:"
        @failure_message_artefacts.each do |error_case|
          message << "  validation failed when provided with a #{error_case[:size]} bytes test file"
        end
        message << "  whereas it should have passed"
      end

      def not_lower_than_min?
        @min.nil? || !passes_validation_with_size(@min - 1)
      end

      def higher_than_min?
        @min.nil? || passes_validation_with_size(@min + 1)
      end

      def lower_than_max?
        @max.nil? || @max == Float::INFINITY || passes_validation_with_size(@max - 1)
      end

      def not_higher_than_max?
        @max.nil? || @max == Float::INFINITY || !passes_validation_with_size(@max + 1)
      end

      def passes_validation_with_size(size)
        mock_size_for(io, size) do
          attach_file
          validate
          detach_file
          is_valid? || add_failure_message_artefact(size)
        end
      end

      def add_failure_message_artefact(size)
        @failure_message_artefacts << { size: size }
        false
      end

      def is_custom_message_valid?
        return true unless @custom_message

        mock_size_for(io, -1.kilobytes) do
          attach_file
          validate
          detach_file
          has_an_error_message_which_is_custom_message?
        end
      end

      def mock_size_for(io, size)
        Matchers.stub_method(io, :size, size) do
          yield
        end
      end
    end
  end
end
