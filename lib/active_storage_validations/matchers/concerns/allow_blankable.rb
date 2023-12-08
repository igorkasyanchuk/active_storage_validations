require "active_support/concern"

module ActiveStorageValidations
  module Matchers
    module AllowBlankable
      extend ActiveSupport::Concern

      def initialize(attribute_name)
        super
        @allow_blank = nil
      end

      def allow_blank
        @allow_blank = true
        self
      end

      private

      def is_allowing_blank?
        return true unless @allow_blank

        validate
      end
    end
  end
end
