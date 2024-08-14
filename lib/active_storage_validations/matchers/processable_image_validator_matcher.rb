# frozen_string_literal: true
require "pry"
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
        binding.pry
        attach_dummy_image unless image_attached?
        validate
        is_valid?
      end

      def is_invalid_when_image_not_processable?
        detach_image if image_attached?
        attach_no_dummy_image
        validate
        !is_valid?
      end

      def is_custom_message_valid?
        return true unless @custom_message

        detach_image if image_attached?
        attach_no_dummy_image
        validate
        has_an_error_message_which_is_custom_message?
      end

      def attach_dummy_image
        dummy_image = {
          io: Tempfile.new('.'),
          filename: 'dummy.jpg',
          content_type: 'image/jpg'
        }

        @subject.public_send(@attribute_name).attach(dummy_image)
      end

      def attach_no_dummy_image
        dummy_image = {
          io: Tempfile.new('.'),
          filename: 'dummy.txt',
          content_type: 'text/plain'
        }

        @subject.public_send(@attribute_name).attach(dummy_image)
      end

      def image_attached?
        @subject.public_send(@attribute_name).attached?
      end

      def detach_image
        @subject.public_send(@attribute_name).detach
        # Unset the direct relation since `detach` on an unpersisted record does not set `attached?` to false.
        @subject.public_send("#{@attribute_name}=", nil)
      end
    end
  end
end
