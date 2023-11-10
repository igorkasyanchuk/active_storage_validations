# frozen_string_literal: true

require_relative 'concerns/symbolizable.rb'

module ActiveStorageValidations
  class AttachedValidator < ActiveModel::EachValidator # :nodoc:
    include ErrorHandler
    include Symbolizable

    ERROR_TYPES = %i[blank].freeze

    def validate_each(record, attribute, _value)
      return if record.send(attribute).attached?

      errors_options = initialize_error_options(options)

      add_error(record, attribute, ERROR_TYPES.first, **errors_options)
    end
  end
end
