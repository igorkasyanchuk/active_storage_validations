# frozen_string_literal: true

require_relative "base_comparison_validator"
require_relative "shared/asv_analyzable"
require_relative "shared/asv_attachable"

module ActiveStorageValidations
  class PagesValidator < BaseComparisonValidator
    include ASVAnalyzable
    include ASVAttachable

    ERROR_TYPES = %i[
      pages_not_less_than
      pages_not_less_than_or_equal_to
      pages_not_greater_than
      pages_not_greater_than_or_equal_to
      pages_not_between
      pages_not_equal_to
    ].freeze
    METADATA_KEYS = %i[pages].freeze

    delegate :number_to_delimited, to: ActiveSupport::NumberHelper

    def validate_each(record, attribute, _value)
      return if no_attachments?(record, attribute)

      validate_changed_files_from_metadata(record, attribute, METADATA_KEYS)
    end

    private

    def is_valid?(record, attribute, file, metadata)
      flat_options = set_flat_options(record)
      errors_options = initialize_error_options(options, file)

      unless valid_metadata?(metadata)
        add_media_metadata_missing_error(record, attribute, file, errors_options)
        return false
      end

      return true if super(metadata[:pages], flat_options)

      populate_error_options(errors_options, flat_options)
      errors_options[:pages] = format_bound_value(metadata[:pages])

      keys = AVAILABLE_CHECKS & flat_options.keys
      error_type = "pages_not_#{keys.first}".to_sym

      add_error(record, attribute, error_type, **errors_options)
      false
    end

    def valid_metadata?(metadata)
      metadata[:pages].to_i > 0
    end

    def format_bound_value(value)
      number_to_delimited(value)
    end
  end
end
