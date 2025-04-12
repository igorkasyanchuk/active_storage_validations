# frozen_string_literal: true

module ActiveStorageValidations
  module ASVBlobMetadatable
    extend ActiveSupport::Concern

    # rubocop:disable Metrics/BlockLength
    included do
      # This method returns the metadata that has been set by our gem.
      # The metadata is stored in the blob's custom metadata. All keys are prefixed with 'asv_'
      # to avoid conflicts with other metadata.
      # It is not to set a active_storage_validation key equal to a a hash of our gem's metadata,
      # because this would result in errors down the road with services such as S3.
      #
      # Because of how the metadata is stored, we need to convert the values from String
      # to Integer or Boolean.
      def active_storage_validations_metadata
        metadata.dig("custom")
                &.select { |key, _| key.to_s.start_with?("asv_") }
                &.transform_keys { |key| key.to_s.delete_prefix("asv_") }
                &.transform_values do |value|
                  case value
                  when /\A\d+\z/ then value.to_i
                  when /\A\d+\.\d+\z/ then value.to_f
                  when "true" then true
                  when "false" then false
                  else value
                  end
                end || {}
      end

      # This method sets the metadata that has been detected by our gem.
      # The metadata is stored in the blob's custom metadata. All keys are prefixed with 'asv_'.
      # We need to store values as String, because services such as S3 will not accept other types.
      def merge_into_active_storage_validations_metadata(hash)
        aws_compatible_metadata = normalize_active_storage_validations_metadata_for_aws(hash)

        metadata["custom"] ||= {}
        metadata["custom"].merge!(aws_compatible_metadata)

        active_storage_validations_metadata
      end

      def normalize_active_storage_validations_metadata_for_aws(hash)
        hash.transform_keys { |key, _| key.to_s.start_with?("asv_") ? key : "asv_#{key}" }
            .transform_values(&:to_s)
      end

      def remove_active_storage_validations_metadata!
        metadata["custom"] ||= {}
        metadata["custom"].delete_if { |key, _| key.to_s.start_with?("asv_") }
      end
    end
    # rubocop:enable Metrics/BlockLength
  end
end
