# frozen_string_literal: true

module ActiveStorageValidations
  module ASVBlobMetadatable
    extend ActiveSupport::Concern

    included do
      # This method returns the metadata that has been set by our gem.
      # The metadata is stored in the blob's custom metadata. All keys are prefixed with 'asv_'
      # to avoid conflicts with other metadata.
      # It is not to set a active_storage_validation key equal to a a hash of our gem's metadata,
      # because this would result in errors down the road with services such as S3.
      def active_storage_validations_metadata
        metadata.dig('custom')
                &.select { |key, _| key.to_s.start_with?('asv_') }
                &.transform_keys { |key| key.to_s.delete_prefix('asv_') } || {}
      end

      # This method sets the metadata that has been detected by our gem.
      # The metadata is stored in the blob's custom metadata. All keys are prefixed with 'asv_'.
      def merge_into_active_storage_validations_metadata(hash)
        metadata['custom'] ||= {}
        metadata['custom'].merge!(hash.transform_keys { |key, _| key.to_s.start_with?('asv_') ? key : "asv_#{key}" })
        active_storage_validations_metadata
      end
    end
  end
end
