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

      def spoofing_protection_description
        case @spoofing_protection
        when UNSET then nil
        when false then "without spoofing protection"
        when true then "with spoofing protection"
        else "with #{@spoofing_protection.inspect} spoofing protection"
        end
      end

      def is_spoofing_protection_valid?
        return true if @spoofing_protection.equal?(UNSET)

        expected = normalize_spoofing_protection(@spoofing_protection)
        attribute_validators.any? do |validator|
          next false unless validator.options.key?(:spoofing_protection)

          normalize_spoofing_protection(validator.options[:spoofing_protection]) == expected
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
