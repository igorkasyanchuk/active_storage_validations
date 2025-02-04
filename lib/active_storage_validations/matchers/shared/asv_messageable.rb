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

      def has_an_error_message_which_is_custom_message?
        validator_errors_for_attribute.one? do |error|
          error[:custom_message] == @custom_message
        end
      end
    end
  end
end
