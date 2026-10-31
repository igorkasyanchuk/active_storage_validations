# frozen_string_literal: true

require "active_support/concern"

module ActiveStorageValidations
  module Matchers
    module ASVValidatable
      extend ActiveSupport::Concern

      # A context Rails never uses, for probes whose default context (:create /
      # :update) is listed in the validator :except_on option.
      PROBE_CONTEXT = :active_storage_validations_matcher_probe

      included do
        prepend SubjectRestoration
      end

      # Puts the caller's record back as it was, whatever the probes did or
      # raised.
      module SubjectRestoration
        def matches?(subject)
          super
        ensure
          restore_subject
        end
      end

      private

      # Probes assign, validate and unassign files over and over on the record
      # the caller passed: its persistence state, id and loaded associations are
      # what the validator's `if:` conditions and Procs read (a `dup` is a new
      # record with an empty association cache). Files are assigned through the
      # attribute writer, which never saves (unlike `attach` on a persisted
      # record), and the record's own pending attachment change and errors are
      # restored once the matcher is done.
      def initialize_subject(subject)
        @subject = subject.is_a?(Class) ? subject.new : subject
        @subject_snapshot = snapshot_subject unless subject.is_a?(Class)
        @default_context = @subject.new_record? ? :create : :update
        @failure_message_artefacts = []
      end

      def snapshot_subject
        changes = @subject.attachment_changes
        {
          change_present: changes.key?(@attribute_name.to_s),
          change: changes[@attribute_name.to_s],
          errors: @subject.errors.dup
        }
      end

      def restore_subject
        return unless @subject_snapshot

        changes = @subject.attachment_changes
        if @subject_snapshot[:change_present]
          changes[@attribute_name.to_s] = @subject_snapshot[:change]
        else
          changes.delete(@attribute_name.to_s)
        end
        @subject.errors.copy!(@subject_snapshot[:errors])
        @subject_snapshot = nil
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
