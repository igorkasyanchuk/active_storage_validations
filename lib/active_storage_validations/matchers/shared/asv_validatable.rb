# frozen_string_literal: true

require "active_support/concern"

module ActiveStorageValidations
  module Matchers
    module ASVValidatable
      extend ActiveSupport::Concern

      private

      def validate
        @subject.validate(@context)
      end

      def validator_errors_for_attribute
        @subject.errors.details[@attribute_name].select do |error|
          error[:validator_type] == validator_class.to_sym
        end
      end

      def is_valid?
        validator_errors_for_attribute.none? do |error|
          error[:error].in?(available_errors)
        end
      end

      def available_errors
        [
          *validator_class::ERROR_TYPES,
          *errors_from_custom_messages
        ].compact
      end

      def validator_class
        self.class.name.gsub(/::Matchers|Matcher/, "").constantize
      end

      def attribute_validator
        @subject.class.validators_on(@attribute_name).find do |validator|
          validator.class == validator_class
        end
      end

      def attribute_validators
        @subject.class.validators_on(@attribute_name).select do |validator|
          validator.class == validator_class
        end
      end

      def errors_from_custom_messages
        attribute_validators.map { |validator| validator.options[:message] }
      end
    end
  end
end
