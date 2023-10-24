# frozen_string_literal: true

module ActiveStorageValidations
  class AttachedValidator < ActiveModel::EachValidator # :nodoc:
    include ErrorHandler

    def validate_each(record, attribute, _value)
      return if record.send(attribute).attached?

      errors_options = initialize_error_options(options)

      add_error(record, attribute, :blank, **errors_options)
    end
  end
end
