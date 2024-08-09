# frozen_string_literal: true

require_relative 'concerns/errorable.rb'
require_relative 'concerns/symbolizable.rb'
require_relative 'base_size_validator.rb'

module ActiveStorageValidations
  class TotalSizeValidator < BaseSizeValidator
    ERROR_TYPES = %i[
      total_file_size_not_less_than
      total_file_size_not_less_than_or_equal_to
      total_file_size_not_greater_than
      total_file_size_not_greater_than_or_equal_to
      total_file_size_not_between
    ].freeze

    def validate_each(record, attribute, _value)
      custom_check_validity!(record, attribute)

      return true unless record.send(attribute).attached?

      files = Array.wrap(record.send(attribute))
      flat_options = unfold_procs(record, self.options, AVAILABLE_CHECKS)

      total_file_size = files.sum { |file| file.blob.byte_size }

      return true if is_valid?(total_file_size, flat_options)

      errors_options = initialize_error_options(options, nil)
      populate_error_options(errors_options, flat_options)
      errors_options[:total_file_size] = number_to_human_size(total_file_size)

      keys = AVAILABLE_CHECKS & flat_options.keys
      error_type = "total_file_size_not_#{keys.first}".to_sym

      add_error(record, attribute, error_type, **errors_options)
    end

    private

    def custom_check_validity!(record, attribute)
      # We can't perform this check in the #check_validity! hook because we do not
      # have enough data (only options & attributes are accessible)
      unless record.send(attribute).is_a?(ActiveStorage::Attached::Many)
        raise ArgumentError, 'This validator is only available for has_many_attached relations'
      end
    end
  end
end
