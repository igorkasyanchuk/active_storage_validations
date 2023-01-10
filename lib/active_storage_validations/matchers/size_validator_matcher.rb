# frozen_string_literal: true

# Big thank you to the paperclip validation matchers:
# https://github.com/thoughtbot/paperclip/blob/v6.1.0/lib/paperclip/matchers/validate_attachment_size_matcher.rb
module ActiveStorageValidations
  module Matchers
    def validate_size_of(name)
      SizeValidatorMatcher.new(name)
    end

    class SizeValidatorMatcher
      def initialize(attribute_name)
        @attribute_name = attribute_name
        @min = @max = nil
        @custom_message = nil
      end

      def description
        "validate file size of #{@attribute_name}"
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

      def with_message(message)
        @custom_message = message
        self
      end

      def matches?(subject)
        @subject = subject.is_a?(Class) ? subject.new : subject
        responds_to_methods && not_lower_than_min? && higher_than_min? && lower_than_max? && not_higher_than_max?
      end

      def failure_message
        "is expected to validate file size of #{@attribute_name} to be between #{@min} and #{@max} bytes"
      end

      def failure_message_when_negated
        "is expected to not validate file size of #{@attribute_name} to be between #{@min} and #{@max} bytes"
      end

      protected

      def responds_to_methods
        @subject.respond_to?(@attribute_name) &&
          @subject.public_send(@attribute_name).respond_to?(:attach) &&
          @subject.public_send(@attribute_name).respond_to?(:detach)
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

      def passes_validation_with_size(new_size)
        io = Tempfile.new('Hello world!')
        Matchers.stub_method(io, :size, new_size) do
          @subject.public_send(@attribute_name).attach(io: io, filename: 'test.png', content_type: 'image/pg')
          @subject.validate
          exclude_error_message = @custom_message || "file_size_not_"
          @subject.errors.details[@attribute_name].none? do |error|
            error[:error].to_s.include?(exclude_error_message)
          end
        end
      end
    end
  end
end
