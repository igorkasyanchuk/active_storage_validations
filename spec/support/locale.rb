I18n.available_locales = Dir[File.expand_path("../../config/locales/*.yml", __dir__)].map { |path| File.basename(path, ".yml") }
