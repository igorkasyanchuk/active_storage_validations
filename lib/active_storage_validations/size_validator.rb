# frozen_string_literal: true

require_relative 'concerns/errorable.rb'
require_relative 'concerns/symbolizable.rb'
require_relative 'base_size_validator.rb'

module ActiveStorageValidations
  class SizeValidator < BaseSizeValidator
    ERROR_TYPES = %i[
      file_size_not_less_than
      file_size_not_less_than_or_equal_to
      file_size_not_greater_than
      file_size_not_greater_than_or_equal_to
      file_size_not_between
    ].freeze

    def validate_each(record, attribute, _value)
      return true unless record.send(attribute).attached?

      files = Array.wrap(record.send(attribute))
      flat_options = unfold_procs(record, self.options, AVAILABLE_CHECKS)

      files.each do |file|
        next if is_valid?(file.blob.byte_size, flat_options)

        errors_options = initialize_error_options(options, file)
        populate_error_options(errors_options, flat_options)
        errors_options[:file_size] = number_to_human_size(file.blob.byte_size)

        keys = AVAILABLE_CHECKS & flat_options.keys
        error_type = "file_size_not_#{keys.first}".to_sym

        add_error(record, attribute, error_type, **errors_options)
        break
      end
    end
  end
end
