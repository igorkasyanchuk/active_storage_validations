# frozen_string_literal: true

require_relative 'concerns/validatable.rb'

module ActiveStorageValidations
  module Matchers
    def validate_attached_of(name)
      AttachedValidatorMatcher.new(name)
    end

    class AttachedValidatorMatcher
      include Validatable

      def initialize(attribute_name)
        @attribute_name = attribute_name
        @custom_message = nil
      end

      def description
        "validate #{@attribute_name} must be attached"
      end

      def with_message(message)
        @custom_message = message
        self
      end

      def matches?(subject)
        @subject = subject.is_a?(Class) ? subject.new : subject
        responds_to_methods &&
          is_valid_when_file_attached? &&
          is_invalid_when_file_not_attached? &&
          validate_custom_message?
      end

      def failure_message
        "is expected to validate attached of #{@attribute_name}"
      end

      def failure_message_when_negated
        "is expected to not validate attached of #{@attribute_name}"
      end

      private

      def responds_to_methods
        @subject.respond_to?(@attribute_name) &&
          @subject.public_send(@attribute_name).respond_to?(:attach) &&
          @subject.public_send(@attribute_name).respond_to?(:detach)
      end

      def is_valid_when_file_attached?
        attach_dummy_file unless file_attached?
        validate
        is_valid?
      end

      def is_invalid_when_file_not_attached?
        detach_file if file_attached?
        validate
        !is_valid?
      end

      def validate_custom_message?
        return true unless @custom_message

        detach_file if file_attached?
        validate
        has_an_error_message_which_is_custom_message?
      end

      def attach_dummy_file
        dummy_file = {
          io: Tempfile.new('.'),
          filename: 'dummy.txt',
          content_type: 'text/plain'
        }

        @subject.public_send(@attribute_name).attach(dummy_file)
      end

      def file_attached?
        @subject.public_send(@attribute_name).attached?
      end

      def detach_file
        @subject.public_send(@attribute_name).detach
        # Unset the direct relation since `detach` on an unpersisted record does not set `attached?` to false.
        @subject.public_send("#{@attribute_name}=", nil)
      end
    end
  end
end
