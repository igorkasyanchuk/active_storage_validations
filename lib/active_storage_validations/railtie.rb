# frozen_string_literal: true

module ActiveStorageValidations
  class Railtie < ::Rails::Railtie
    # Using after: :load_config_initializers would cause a stack level too deep error
    # See: https://github.com/igorkasyanchuk/active_storage_validations/issues/364

    initializer "active_storage_validations.configure" do
      ActiveSupport.on_load(:active_record) do
        include ActiveStorageValidations
      end
    end

    initializer "active_storage_validations.extend_active_storage_blob" do
      ActiveSupport.on_load(:active_storage_blob) do
        include ActiveStorageValidations::ASVBlobMetadatable
      end
    end
  end
end
