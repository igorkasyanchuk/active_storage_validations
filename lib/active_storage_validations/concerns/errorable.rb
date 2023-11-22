module ActiveStorageValidations
  module Errorable
    extend ActiveSupport::Concern

    def initialize_error_options(options)
      not_explicitly_written_options = %i(with in)
      curated_options = options.except(*not_explicitly_written_options)

      active_storage_validations_options = {
        validator_type: self.class.to_sym,
        custom_message: (options[:message] if options[:message].present?)
      }.compact

      curated_options.merge(active_storage_validations_options)
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
