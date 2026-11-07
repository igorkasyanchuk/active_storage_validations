# frozen_string_literal: true

require "active_support/concern"

module ActiveStorageValidations
  module Matchers
    module ASVSpoofingProtectable
      extend ActiveSupport::Concern

      UNSET = Object.new.freeze

      def initialize_spoofing_protectable
        @spoofing_protection = UNSET
      end

      def spoofing_protection(value = true)
        @spoofing_protection = value
        self
      end

      private

      def is_spoofing_protection_valid?
        return true if @spoofing_protection.equal?(UNSET)

        expected = normalize_spoofing_protection(@spoofing_protection)
        # The validator option defaults to false.
        attribute_validators.any? do |validator|
          normalize_spoofing_protection(validator.options.fetch(:spoofing_protection, false)) == expected
        end
      end

      def normalize_spoofing_protection(value)
        case value
        when true, :file then :file
        when :magika then :magika
        when false then false
        else value
        end
      end
    end
  end
end
