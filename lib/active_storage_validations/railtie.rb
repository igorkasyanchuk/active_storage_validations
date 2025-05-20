# frozen_string_literal: true

module ActiveStorageValidations
  class Railtie < ::Rails::Railtie
    initializer "active_storage_validations.configure" do
      ActiveSupport.on_load(:active_record) do
        include ActiveStorageValidations unless included_modules.include?(ActiveStorageValidations)
      end
    end

    initializer "active_storage_validations.extend_active_storage_blob" do
      ActiveSupport.on_load(:active_storage_blob) do
        include ActiveStorageValidations::ASVBlobMetadatable
      end
    end
  end
end
