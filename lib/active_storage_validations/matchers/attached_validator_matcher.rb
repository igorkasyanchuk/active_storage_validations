# frozen_string_literal: true

module ActiveStorageValidations
  module Matchers
    def validate_attached_of(name)
      AttachedValidatorMatcher.new(name)
    end

    class AttachedValidatorMatcher
      def initialize(attribute_name)
        @attribute_name = attribute_name
      end

      def description
        "validate #{@attribute_name} must be attached"
      end

      def matches?(subject)
        @subject = subject.is_a?(Class) ? subject.new : subject
        responds_to_methods && valid_when_attached && invalid_when_not_attached
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

      def valid_when_attached
        @subject.public_send(@attribute_name).attach(attachable) unless @subject.public_send(@attribute_name).attached?
        @subject.validate
        @subject.errors.details[@attribute_name].exclude?(error: :blank)
      end

      def invalid_when_not_attached
        @subject.public_send(@attribute_name).detach
        # Unset the direct relation since `detach` on an unpersisted record does not set `attached?` to false.
        @subject.public_send("#{@attribute_name}=", nil)

        @subject.validate
        @subject.errors.details[@attribute_name].include?(error: :blank)
      end

      def attachable
        { io: Tempfile.new('.'), filename: 'dummy.txt', content_type: 'text/plain' }
      end
    end
  end
end
