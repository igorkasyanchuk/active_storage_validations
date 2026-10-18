# frozen_string_literal: true

require "active_support/concern"

module ActiveStorageValidations
  module Matchers
    module ASVValidatable
      extend ActiveSupport::Concern

      # A context Rails never uses, for probes whose default context (:create /
      # :update) is listed in the validator :except_on option.
      PROBE_CONTEXT = :active_storage_validations_matcher_probe

      private

      # Probes attach, validate and detach files over and over. Run them on a
      # copy so the caller's record keeps its own pending attachments and is
      # never saved (`attach` saves a persisted record). The copy is a new
      # record, so keep the validation context the original would have used.
      def initialize_subject(subject)
        if subject.is_a?(Class)
          @subject = subject.new
          @default_context = :create
        else
          @subject = subject.dup
          @default_context = subject.new_record? ? :create : :update
        end
        @failure_message_artefacts = []
      end

      def validate
        @subject.validate(validation_context)
      end

      # Without #on, validate in the record default context, unless the
      # validator skips it (e.g. `except_on: :create`): no probe would ever run
      # the validator then.
      def validation_context
        return @context if @context
        return PROBE_CONTEXT if validator_except_on_contexts.include?(@default_context.to_s)

        @default_context
      end

      def has_validator?
        attribute_validators.any?
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
