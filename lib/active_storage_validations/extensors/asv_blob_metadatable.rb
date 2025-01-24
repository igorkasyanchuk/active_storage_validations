# frozen_string_literal: true

module ActiveStorageValidations
  module ASVBlobMetadatable
    extend ActiveSupport::Concern

    included do
      def active_storage_validations_metadata
        metadata.dig('custom', 'active_storage_validations') || {}
      end

      def active_storage_validations_metadata=(value)
        metadata['custom'] ||= {}
        metadata['custom']['active_storage_validations'] = value
      end

      def merge_into_active_storage_validations_metadata(new_data)
        metadata['custom'] ||= {}
        metadata['custom']['active_storage_validations'] ||= {}
        metadata['custom']['active_storage_validations'].merge!(new_data)
      end
    end
  end
end
