# frozen_string_literal: true

require "active_support/concern"

module ActiveStorageValidations
  module Matchers
    module ASVValidatable
      extend ActiveSupport::Concern

      # Matchers read the errors of each probe, but a `strict: true` validator
      # (on this attribute or any other) raises ActiveModel::StrictValidationFailed
      # instead of adding its error. During a probe, strict errors are added as
      # plain ones; validations outside the matcher still raise.
      module NonStrictProbeErrors
        KEY = :active_storage_validations_matcher_probe

        def add(attribute, type = :invalid, **options)
          options = options.except(:strict) if ActiveSupport::IsolatedExecutionState[KEY]
          super
        end
      end

      private

      def validate
        ActiveModel::Errors.prepend(NonStrictProbeErrors) unless ActiveModel::Errors.include?(NonStrictProbeErrors)
        previous = ActiveSupport::IsolatedExecutionState[NonStrictProbeErrors::KEY]
        ActiveSupport::IsolatedExecutionState[NonStrictProbeErrors::KEY] = true
        @subject.validate(@context)
      ensure
        ActiveSupport::IsolatedExecutionState[NonStrictProbeErrors::KEY] = previous
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
