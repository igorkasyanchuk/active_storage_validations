# frozen_string_literal: true

module ActiveStorageValidations
  class Railtie < ::Rails::Railtie
    config.after_initialize do
      ActiveStorageValidations::IMAGE_PROCESSOR = Rails.application.config.active_storage.variant_processor
    end
  end
end
