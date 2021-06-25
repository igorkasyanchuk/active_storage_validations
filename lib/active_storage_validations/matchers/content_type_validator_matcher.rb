# frozen_string_literal: true

# Big thank you to the paperclip validation matchers:
# https://github.com/thoughtbot/paperclip/blob/v6.1.0/lib/paperclip/matchers/validate_attachment_content_type_matcher.rb
module ActiveStorageValidations
  module Matchers
    def validate_content_type_of(name)
      ContentTypeValidatorMatcher.new(name)
    end

    class ContentTypeValidatorMatcher
      def initialize(attribute_name)
        @attribute_name = attribute_name
      end

      def description
        "validate the content types allowed on attachment #{@attribute_name}"
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
        responds_to_methods && allowed_types_allowed? && rejected_types_rejected?
      end

      def failure_message
        <<~MESSAGE
          Expected #{@attribute_name}
            
            Accept content types: #{allowed_types.join(", ")}
              #{accepted_types_and_failures}

            Reject content types: #{rejected_types.join(", ")}
              #{rejected_types_and_failures}
        MESSAGE
      end

      protected

      def responds_to_methods
        @subject.respond_to?(@attribute_name) &&
          @subject.public_send(@attribute_name).respond_to?(:attach) &&
          @subject.public_send(@attribute_name).respond_to?(:detach)
      end

      def allowed_types
        @allowed_types || []
      end

      def rejected_types
        @rejected_types || (Marcel::TYPES.keys - allowed_types)
      end

      def allowed_types_allowed?
        @missing_allowed_types ||= allowed_types.reject { |type| type_allowed?(type) }
        @missing_allowed_types.none?
      end

      def rejected_types_rejected?
        @missing_rejected_types ||= rejected_types.select { |type| type_allowed?(type) }
        @missing_rejected_types.none?
      end

      def accepted_types_and_failures
        if @missing_allowed_types.present?
          "#{@missing_allowed_types.join(", ")} were rejected."
        else
          "All were accepted successfully."
        end
      end

      def rejected_types_and_failures
        if @missing_rejected_types.present?
          "#{@missing_rejected_types.join(", ")} were accepted."
        else
          "All were rejected successfully."
        end
      end

      def type_allowed?(type)
        @subject.public_send(@attribute_name).attach(attachment_for(type))
        @subject.validate
        @subject.errors.details[@attribute_name].all? { |error| error[:error] != :content_type_invalid }
      end

      def attachment_for(type)
        suffix = type.to_s.split('/').last
        { io: Tempfile.new('.'), filename: "test.#{suffix}", content_type: type }
      end
    end
  end
end
