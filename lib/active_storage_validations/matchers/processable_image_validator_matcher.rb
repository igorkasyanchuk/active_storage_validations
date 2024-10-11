# frozen_string_literal: true

require_relative 'concerns/active_storageable.rb'
require_relative 'concerns/allow_blankable.rb'
require_relative 'concerns/attachable.rb'
require_relative 'concerns/contextable.rb'
require_relative 'concerns/messageable.rb'
require_relative 'concerns/rspecable.rb'
require_relative 'concerns/validatable.rb'

module ActiveStorageValidations
  module Matchers
    def validate_processable_image_of(name)
      ProcessableImageValidatorMatcher.new(name)
    end

    class ProcessableImageValidatorMatcher
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
      end

      def description
        "validate that :#{@attribute_name} is a processable image"
      end

      def failure_message
        "is expected to validate the processable image of :#{@attribute_name}"
      end

      def matches?(subject)
        @subject = subject.is_a?(Class) ? subject.new : subject

        is_a_valid_active_storage_attribute? &&
        is_context_valid? &&
        is_custom_message_valid? &&
        is_valid_when_image_processable? &&
        is_invalid_when_image_not_processable?
      end

      private

      def is_valid_when_image_processable?
        attach_file(processable_image)
        validate
        detach_file
        is_valid?
      end

      def is_invalid_when_image_not_processable?
        attach_file(not_processable_image)
        validate
        detach_file
        !is_valid?
      end

      def is_custom_message_valid?
        return true unless @custom_message

        attach_file(not_processable_image)
        validate
        detach_file
        has_an_error_message_which_is_custom_message?
      end
    end
  end
end
