# frozen_string_literal: true

# Big thank you to the paperclip validation matchers:
# https://github.com/thoughtbot/paperclip/blob/v6.1.0/lib/paperclip/matchers/validate_attachment_content_type_matcher.rb

require_relative "shared/asv_active_storageable"
require_relative "shared/asv_allow_blankable"
require_relative "shared/asv_attachable"
require_relative "shared/asv_contextable"
require_relative "shared/asv_messageable"
require_relative "shared/asv_rspecable"
require_relative "shared/asv_validatable"

module ActiveStorageValidations
  module Matchers
    def validate_content_type_of(attribute_name)
      ContentTypeValidatorMatcher.new(attribute_name)
    end

    class ContentTypeValidatorMatcher
      include ASVActiveStorageable
      include ASVAllowBlankable
      include ASVAttachable
      include ASVContextable
      include ASVMessageable
      include ASVRspecable
      include ASVValidatable

      def initialize(attribute_name)
        initialize_allow_blankable
        initialize_contextable
        initialize_messageable
        initialize_rspecable
        @attribute_name = attribute_name
        @allowed_content_types = @rejected_content_types = []
      end

      def description
        "validate the content types allowed on :#{@attribute_name}"
      end

      def failure_message
        message = [ "is expected to validate the content types of :#{@attribute_name}" ]
        build_failure_message(message)
        message.join("\n")
      end

      def allowing(*content_types)
        types = content_types.flatten
        @allowed_content_types = types.map { |content_type| normalize_content_type(content_type) }.flatten
        self
      end

      def rejecting(*content_types)
        types = content_types.flatten
        @rejected_content_types = types.map { |content_type| normalize_content_type(content_type) }.flatten
        self
      end

      def matches?(subject)
        @subject = subject.is_a?(Class) ? subject.new : subject

        is_a_valid_active_storage_attribute? &&
          is_context_valid? &&
          is_allowing_blank? &&
          is_custom_message_valid? &&
          all_allowed_content_types_allowed? &&
          all_rejected_content_types_rejected?
      end

      protected

      def build_failure_message(message)
        if @allowed_content_types_not_allowed.present?
          message << "  the following content type#{'s' if @allowed_content_types.count > 1} should be allowed: :#{@allowed_content_types.join(", :")}"
          message << "  but #{pluralize(@allowed_content_types_not_allowed)} rejected"
        end

        if @rejected_content_types_not_rejected.present?
          message << "  the following content type#{'s' if @rejected_content_types.count > 1} should be rejected: :#{@rejected_content_types.join(", :")}"
          message << "  but #{pluralize(@rejected_content_types_not_rejected)} accepted"
        end
      end

      def pluralize(types)
        if types.count == 1
          ":#{types[0]} was"
        else
          ":#{types.join(", :")} were"
        end
      end

      def normalize_content_type(content_type)
        Marcel::MimeType.for(declared_type: content_type.to_s, extension: content_type.to_s)
      end

      def all_allowed_content_types_allowed?
        @allowed_content_types_not_allowed ||= @allowed_content_types.reject { |type| type_allowed?(type) }
        @allowed_content_types_not_allowed.empty?
      end

      def all_rejected_content_types_rejected?
        @rejected_content_types_not_rejected ||= @rejected_content_types.select { |type| type_allowed?(type) }
        @rejected_content_types_not_rejected.empty?
      end

      def type_allowed?(content_type)
        attach_file_with_content_type(content_type)
        validate
        detach_file
        is_valid?
      end

      def attach_file_with_content_type(content_type)
        @subject.public_send(@attribute_name).attach(attachment_for(content_type))
      end

      def is_custom_message_valid?
        return true unless @custom_message

        attach_invalid_content_type_file
        validate
        has_an_error_message_which_is_custom_message?
      end

      def attach_invalid_content_type_file
        @subject.public_send(@attribute_name).attach(attachment_for("fake/fake"))
      end

      def attachment_for(content_type)
        suffix = Marcel::TYPE_EXTS[content_type.to_s]&.first || "fake"

        {
          io: Tempfile.new("."),
          filename: "test.#{suffix}",
          content_type: content_type
        }
      end

      # Due to the way we build test attachments in #attachment_for
      # (ie spoofed file basically), we need to ignore the error related to
      # content type spoofing in our matcher to pass the tests
      def validator_errors_for_attribute
        super.reject { |hash| hash[:error] == :content_type_spoofed }
      end
    end
  end
end
