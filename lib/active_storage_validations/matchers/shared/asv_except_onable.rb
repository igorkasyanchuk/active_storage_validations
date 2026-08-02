# frozen_string_literal: true

require "active_support/concern"

module ActiveStorageValidations
  module Matchers
    module ASVExceptOnable
      extend ActiveSupport::Concern

      def initialize_except_onable
        @except_on = nil
      end

      def except_on(context)
        @except_on = context
        self
      end

      private

      def is_except_on_valid?
        return true if !@except_on && attribute_validators.none? { |validator| validator.options[:except_on] }

        ensure_except_on_present!
        ensure_except_on_valid!

        if @except_on.is_a?(Array)
          (validator_except_on_contexts & @except_on.map(&:to_s)) == validator_except_on_contexts || raise_except_on_not_listed_error
        elsif @except_on.is_a?(Symbol)
          validator_except_on_contexts.include?(@except_on.to_s) || raise_except_on_not_listed_error
        end
      end

      def ensure_except_on_present!
        raise ArgumentError, "This validator matcher needs the #except_on option to work since its validator has one" if !@except_on && attribute_validators.all? { |validator| validator.options[:except_on] }
      end

      def ensure_except_on_valid!
        raise ArgumentError, "This validator matcher option only allows a symbol or an array" if !(@except_on.is_a?(Symbol) || @except_on.is_a?(Array))
      end

      def validator_except_on_contexts
        attribute_validators.map do |validator|
          case validator.options[:except_on]
          when Array then validator.options[:except_on].map { |context| context.to_s }
          when NilClass then nil
          else validator.options[:except_on].to_s
          end
        end.flatten.compact
      end

      def raise_except_on_not_listed_error
        raise ArgumentError, "One of the provided contexts to the #except_on method is not found in any of the listed contexts for this attribute"
      end
    end
  end
end
