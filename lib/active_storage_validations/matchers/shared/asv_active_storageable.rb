# frozen_string_literal: true

require "active_support/concern"

module ActiveStorageValidations
  module Matchers
    module ASVActiveStorageable
      extend ActiveSupport::Concern

      private

      def is_a_valid_active_storage_attribute?
        @subject.respond_to?(@attribute_name) &&
          @subject.public_send(@attribute_name).respond_to?(:attach) &&
          @subject.public_send(@attribute_name).respond_to?(:detach)
      end
    end
  end
end
