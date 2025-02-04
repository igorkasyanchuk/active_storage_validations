# frozen_string_literal: true

require "active_support/concern"

module ActiveStorageValidations
  module Matchers
    module ASVAllowBlankable
      extend ActiveSupport::Concern

      def initialize_allow_blankable
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
