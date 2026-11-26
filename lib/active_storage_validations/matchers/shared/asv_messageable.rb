# frozen_string_literal: true

require "active_support/concern"

module ActiveStorageValidations
  module Matchers
    module ASVMessageable
      extend ActiveSupport::Concern

      def initialize_messageable
        @custom_message = nil
      end

      def with_message(custom_message)
        @custom_message = custom_message
        self
      end

      private

      def custom_message_description
        "with message #{@custom_message.inspect}" if @custom_message
      end

      # Several validators may share the message and all reject the probe.
      # The expected message is the validator's +message:+ option as declared
      # (a String, a Symbol) or the message the error renders (the gem's
      # translation when no +message:+ is given). A Regexp matches either text.
      def has_an_error_message_which_is_custom_message?
        validator_error_objects.any? do |error|
          custom_message_matches?(error.options[:custom_message]) || custom_message_matches?(error.message)
        end
      end

      def custom_message_matches?(message)
        case @custom_message
        when Regexp then message.is_a?(String) && @custom_message.match?(message)
        else message == @custom_message
        end
      end

      def validator_error_objects
        @subject.errors.objects.select do |error|
          error.attribute == @attribute_name.to_sym && error.options[:validator_type] == validator_class.to_sym
        end
      end
    end
  end
end
