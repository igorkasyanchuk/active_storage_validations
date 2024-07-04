# frozen_string_literal: true

# Big thank you to the paperclip validation matchers:
# https://github.com/thoughtbot/paperclip/blob/v6.1.0/lib/paperclip/matchers/validate_attachment_content_type_matcher.rb

require_relative 'concerns/active_storageable.rb'
require_relative 'concerns/allow_blankable.rb'
require_relative 'concerns/attachable.rb'
require_relative 'concerns/contextable.rb'
require_relative 'concerns/messageable.rb'
require_relative 'concerns/rspecable.rb'
require_relative 'concerns/validatable.rb'

module ActiveStorageValidations
  module Matchers
    def validate_content_type_of(attribute_name)
      ContentTypeValidatorMatcher.new(attribute_name)
    end

    class ContentTypeValidatorMatcher
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
        @allowed_types = @rejected_types = []
      end

      def description
        "validate the content types allowed on :#{@attribute_name}"
      end

      def failure_message
        message = ["is expected to validate the content types of :#{@attribute_name}"]
        build_failure_message(message)
        message.join("\n")
      end

      def allowing(*types)
        @allowed_types = types.flatten
        self
      end

      def rejecting(*types)
        @rejected_types = types.flatten
        self
      end

      def matches?(subject)
        @subject = subject.is_a?(Class) ? subject.new : subject

        is_a_valid_active_storage_attribute? &&
          is_context_valid? &&
          is_allowing_blank? &&
          is_custom_message_valid? &&
          all_allowed_types_allowed? &&
          all_rejected_types_rejected?
      end

      protected

      def build_failure_message(message)
        if @allowed_types_not_allowed.present?
          message << "  the following content type#{'s' if @allowed_types.count > 1} should be allowed: :#{@allowed_types.join(", :")}"
          message << "  but #{pluralize(@allowed_types_not_allowed)} rejected"
        end

        if @rejected_types_not_rejected.present?
          message << "  the following content type#{'s' if @rejected_types.count > 1} should be rejected: :#{@rejected_types.join(", :")}"
          message << "  but #{pluralize(@rejected_types_not_rejected)} accepted"
        end
      end

      def pluralize(types)
        if types.count == 1
          ":#{types[0]} was"
        else
          ":#{types.join(", :")} were"
        end
      end

      def all_allowed_types_allowed?
        @allowed_types_not_allowed ||= @allowed_types.reject { |type| type_allowed?(type) }
        @allowed_types_not_allowed.empty?
      end

      def all_rejected_types_rejected?
        @rejected_types_not_rejected ||= @rejected_types.select { |type| type_allowed?(type) }
        @rejected_types_not_rejected.empty?
      end

      def type_allowed?(type)
        attach_file_of_type(type)
        validate
        detach_file
        is_valid?
      end

      def attach_file_of_type(type)
        @subject.public_send(@attribute_name).attach(attachment_for(type))
      end

      def is_custom_message_valid?
        return true unless @custom_message

        attach_invalid_content_type_file
        validate
        has_an_error_message_which_is_custom_message?
      end

      def attach_invalid_content_type_file
        @subject.public_send(@attribute_name).attach(attachment_for('fake/fake'))
      end

      def attachment_for(type)
        suffix = type.to_s.split('/').last

        {
          io: Tempfile.new('.'),
          filename: "test.#{suffix}",
          content_type: type
        }
      end
    end
  end
end
