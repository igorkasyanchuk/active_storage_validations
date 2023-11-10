module ActiveStorageValidations
  module ErrorHandler

    def initialize_error_options(options)
      {
        validator_type: self.class.to_sym,
        custom_message: (options[:message] if options[:message].present?)
      }.compact
    end

    def add_error(record, attribute, error_type, **errors_options)
      type = errors_options[:custom_message].presence || error_type
      return if record.errors.added?(attribute, type)

      # You can read https://api.rubyonrails.org/classes/ActiveModel/Errors.html#method-i-add
      # to better understand how Rails model errors work
      record.errors.add(attribute, type, **errors_options)
    end

  end
end
