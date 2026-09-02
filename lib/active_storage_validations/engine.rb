# frozen_string_literal: true

module ActiveStorageValidations
  # Registers the gem as a Rails engine so `config/locales/*.yml` is added to
  # the I18n load path. Initializers live on {Railtie} (Active Record include,
  # FormBuilder prepend, Blob metadata).
  class Engine < ::Rails::Engine
  end
end
