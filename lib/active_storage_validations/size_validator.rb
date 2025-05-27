# frozen_string_literal: true

require_relative "base_comparison_validator"

module ActiveStorageValidations
  class SizeValidator < BaseComparisonValidator
    ERROR_TYPES = %i[
      file_size_not_less_than
      file_size_not_less_than_or_equal_to
      file_size_not_greater_than
      file_size_not_greater_than_or_equal_to
      file_size_not_between
      file_size_not_equal_to
    ].freeze

    delegate :number_to_human_size, to: ActiveSupport::NumberHelper

    def validate_each(record, attribute, _value)
      return if no_attachments?(record, attribute)

      flat_options = set_flat_options(record)

      attached_files(record, attribute).each do |file|
        next if is_valid?(file.blob.byte_size, flat_options)

        errors_options = initialize_error_options(options, file)
        populate_error_options(errors_options, flat_options)
        errors_options[:file_size] = format_bound_value(file.blob.byte_size)

        keys = AVAILABLE_CHECKS & flat_options.keys
        error_type = "file_size_not_#{keys.first}".to_sym

        add_error(record, attribute, error_type, **errors_options)
      end
    end

    private

    def format_bound_value(value)
      number_to_human_size(value)
    end
  end
end
