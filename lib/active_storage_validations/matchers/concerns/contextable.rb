require "active_support/concern"

module ActiveStorageValidations
  module Matchers
    module Contextable
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
        return true if !@context && !(attribute_validator && attribute_validator.options[:on])

        raise ArgumentError, "This validator matcher needs the #on option to work since its validator has one" if !@context
        raise ArgumentError, "This validator matcher option only allows a symbol or an array" if !(@context.is_a?(Symbol) || @context.is_a?(Array))

        if @context.is_a?(Array) && attribute_validator.options[:on].is_a?(Array)
          @context.to_set == attribute_validator.options[:on].to_set
        elsif @context.is_a?(Symbol) && attribute_validator.options[:on].is_a?(Symbol)
          @context == attribute_validator.options[:on]
        else
          false
        end
      end
    end
  end
end
