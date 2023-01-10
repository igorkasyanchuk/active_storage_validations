module ActiveStorageValidations
  module ErrorHandler

    def initialize_error_options(options)
      {
        message: (options[:message] if options[:message].present?)
      }
    end

    def add_error(record, attribute, default_message, **errors_options)
      message = errors_options[:message].presence || default_message
      return if record.errors.added?(attribute, message)

      record.errors.add(attribute, message, **errors_options)
    end

  end
end
