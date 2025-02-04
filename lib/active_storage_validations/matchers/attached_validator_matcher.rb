# frozen_string_literal: true

require_relative "shared/asv_active_storageable"
require_relative "shared/asv_attachable"
require_relative "shared/asv_contextable"
require_relative "shared/asv_messageable"
require_relative "shared/asv_rspecable"
require_relative "shared/asv_validatable"

module ActiveStorageValidations
  module Matchers
    def validate_attached_of(attribute_name)
      AttachedValidatorMatcher.new(attribute_name)
    end

    class AttachedValidatorMatcher
      include ASVActiveStorageable
      include ASVAttachable
      include ASVContextable
      include ASVMessageable
      include ASVRspecable
      include ASVValidatable

      def initialize(attribute_name)
        initialize_contextable
        initialize_messageable
        initialize_rspecable
        @attribute_name = attribute_name
      end

      def description
        "validate that :#{@attribute_name} must be attached"
      end

      def failure_message
        "is expected to validate attachment of :#{@attribute_name}"
      end

      def matches?(subject)
        @subject = subject.is_a?(Class) ? subject.new : subject

        is_a_valid_active_storage_attribute? &&
          is_context_valid? &&
          is_custom_message_valid? &&
          is_valid_when_file_attached? &&
          is_invalid_when_file_not_attached?
      end

      private

      def is_valid_when_file_attached?
        attach_file unless file_attached?
        validate
        is_valid?
      end

      def is_invalid_when_file_not_attached?
        detach_file if file_attached?
        validate
        !is_valid?
      end

      def is_custom_message_valid?
        return true unless @custom_message

        detach_file if file_attached?
        validate
        has_an_error_message_which_is_custom_message?
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
