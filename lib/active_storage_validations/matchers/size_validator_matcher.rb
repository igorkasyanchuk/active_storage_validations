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
        @low = @high = nil
      end

      def description
        "validate file size of #{@attribute_name}"
      end

      def less_than(size)
        @high = size - 1.byte
        self
      end

      def less_than_or_equal_to(size)
        @high = size
        self
      end

      def greater_than(size)
        @low = size + 1.byte
        self
      end

      def greater_than_or_equal_to(size)
        @low = size
        self
      end

      def between(range)
        @low, @high = range.first, range.last
        self
      end

      def matches?(subject)
        @subject = subject.is_a?(Class) ? subject.new : subject
        responds_to_methods && lower_than_low? && higher_than_low? && lower_than_high? && higher_than_high?
      end

      def failure_message
        "is expected to validate file size of #{@attribute_name} to be between #{@low} and #{@high} bytes"
      end

      def failure_message_when_negated
        "is expected to not validate file size of #{@attribute_name} to be between #{@low} and #{@high} bytes"
      end

      protected

      def responds_to_methods
        @subject.respond_to?(@attribute_name) &&
          @subject.public_send(@attribute_name).respond_to?(:attach) &&
          @subject.public_send(@attribute_name).respond_to?(:detach)
      end

      def lower_than_low?
        @low.nil? || !passes_validation_with_size(@low - 1)
      end

      def higher_than_low?
        @low.nil? || passes_validation_with_size(@low + 1)
      end

      def lower_than_high?
        @high.nil? || @high == Float::INFINITY || passes_validation_with_size(@high - 1)
      end

      def higher_than_high?
        @high.nil? || @high == Float::INFINITY || !passes_validation_with_size(@high + 1)
      end

      def passes_validation_with_size(new_size)
        io = Tempfile.new('Hello world!')
        Matchers.stub_method(io, :size, new_size) do
          @subject.public_send(@attribute_name).attach(io: io, filename: 'test.png', content_type: 'image/pg')
          @subject.validate
          @subject.errors.details[@attribute_name].all? { |error| error[:error] != :file_size_out_of_range }
        end
      end
    end
  end
end
