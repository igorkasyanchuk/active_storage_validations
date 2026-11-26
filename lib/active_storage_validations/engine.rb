# frozen_string_literal: true

require "rails/engine"

module ActiveStorageValidations
  # Registers the gem as a Rails engine so `config/locales/*.yml` is added to
  # the I18n load path. Initializers live on {Railtie} (Active Record include,
  # FormBuilder prepend, Blob metadata). An engine also loads
  # +lib/tasks/*.rake+ into the app's tasks: do not load them from the Railtie
  # as well, or each task would run twice.
  class Engine < ::Rails::Engine
  end
end
