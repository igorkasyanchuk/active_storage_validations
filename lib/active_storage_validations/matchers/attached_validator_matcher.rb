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
        @subject = subject.is_a?(Class) ? subject : subject.class

        invalid_when_not_attached && valid_when_attached
      end

      def failure_message
        "is expected to validate attached of #{@attribute_name}"
      end

      def failure_message_when_negated
        "is expected to not validate attached of #{@attribute_name}"
      end

      private

      def valid_when_attached
        instance = @subject.new
        instance.public_send(@attribute_name).attach(attachable)
        instance.validate
        instance.errors.details[@attribute_name].exclude?(error: :blank)
      end

      def invalid_when_not_attached
        instance = @subject.new
        instance.validate
        instance.errors.details[@attribute_name].include?(error: :blank)
      end

      def attachable
        { io: Tempfile.new('.'), filename: 'dummy.txt', content_type: 'text/plain' }
      end
    end
  end
end
