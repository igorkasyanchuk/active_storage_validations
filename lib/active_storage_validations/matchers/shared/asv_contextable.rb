# frozen_string_literal: true

require "active_support/concern"

module ActiveStorageValidations
  module Matchers
    module ASVContextable
      extend ActiveSupport::Concern

      def initialize_contextable
        @context = nil
      end

      def on(context)
        @context = context
        self
      end

      private

      def is_context_valid?
        return true if !@context && attribute_validators.none? { |validator| validator.options[:on] }

        ensure_context_present!
        ensure_context_valid!

        if @context.is_a?(Array)
          (validator_contexts & @context.map(&:to_s)) == validator_contexts || raise_context_not_listed_error
        elsif @context.is_a?(Symbol)
          validator_contexts.include?(@context.to_s) || raise_context_not_listed_error
        end
      end

      def ensure_context_present!
        raise ArgumentError, "This validator matcher needs the #on option to work since its validator has one" if !@context && attribute_validators.all? { |validator| validator.options[:on] }
      end

      def ensure_context_valid!
        raise ArgumentError, "This validator matcher option only allows a symbol or an array" if !(@context.is_a?(Symbol) || @context.is_a?(Array))
      end

      def validator_contexts
        attribute_validators.map do |validator|
          case validator.options[:on]
          when Array then validator.options[:on].map { |context| context.to_s }
          when NilClass then nil
          else validator.options[:on].to_s
          end
        end.flatten.compact
      end

      def raise_context_not_listed_error
        raise ArgumentError, "One of the provided contexts to the #on method is not found in any of the listed contexts for this attribute"
      end
    end
  end
end
