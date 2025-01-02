# frozen_string_literal: true

module ActiveStorageValidations
  class Railtie < ::Rails::Railtie
    initializer 'active_storage_validations.extend_active_storage_blob' do
      Rails.application.config.to_prepare do
        ActiveStorage::Blob.include(ActiveStorageValidations::ASVBlobMetadatable)
      end
    end
  end
end
