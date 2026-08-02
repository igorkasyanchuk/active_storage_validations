# frozen_string_literal: true

require "active_support/concern"

module ActiveStorageValidations
  module Matchers
    module ASVTimeoutable
      extend ActiveSupport::Concern

      UNSET = Object.new.freeze

      def initialize_timeoutable
        @timeout = UNSET
      end

      def timeout(value)
        @timeout = value
        self
      end

      private

      def is_timeout_valid?
        return true if @timeout.equal?(UNSET)

        attribute_validators.any? do |validator|
          validator.options.key?(:timeout) && validator.options[:timeout] == @timeout
        end
      end
    end
  end
end
