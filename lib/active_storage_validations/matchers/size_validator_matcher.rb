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
        lower_than_low? && higher_than_low? && lower_than_high? && higher_than_high?
      end

      def failure_message
        "is expected to validate file size of #{@attribute_name} to be between #{@low} and #{@high} bytes"
      end

      def failure_message_when_negated
        "is expected to not validate file size of #{@attribute_name} to be between #{@low} and #{@high} bytes"
      end

      protected

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
        @subject.public_send(@attribute_name).attach attachment_for(new_size)
        @subject.validate
        @subject.errors.details[@attribute_name].all? { |error| error[:error] != :file_size_out_of_range }
      end

      def override_method(object, method, &replacement)
        (class << object; self; end).class_eval do
          undef_method(method) if method_defined?(method)
          define_method(method, &replacement)
        end
      end

      def attachment_for(size)
        io = Tempfile.new('Hello world!')
        override_method(io, :size) { size }
        { io: io, filename: 'test.png', content_type: 'image/pg' }
      end
    end
  end
end
