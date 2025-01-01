# frozen_string_literal: true

require_relative 'base_comparison_validator'

module ActiveStorageValidations
  class DurationValidator < BaseComparisonValidator
    include ASVAnalyzable
    include ASVAttachable

    ERROR_TYPES = %i[
      duration_not_less_than
      duration_not_less_than_or_equal_to
      duration_not_greater_than
      duration_not_greater_than_or_equal_to
      duration_not_between
    ].freeze

    def validate_each(record, attribute, _value)
      return if no_attachments?(record, attribute)

      flat_options = set_flat_options(record)

      attachables_and_blobs(record, attribute).each do |attachable, blob|
        duration = metadata_for(attachable)[:duration]

        if duration.to_i <= 0
          errors_options = initialize_error_options(options, attachable)
          add_error(record, attribute, :media_metadata_missing, **errors_options)
          next
        end

        next if is_valid?(duration, flat_options)

        errors_options = initialize_error_options(options, attachable)
        populate_error_options(errors_options, flat_options)
        errors_options[:duration] = format_bound_value(duration)

        keys = AVAILABLE_CHECKS & flat_options.keys
        error_type = "duration_not_#{keys.first}".to_sym

        add_error(record, attribute, error_type, **errors_options)
      end
    end

    private

    def format_bound_value(value)
      return nil unless value

      custom_value = value == value.to_i ? value.to_i : value
      ActiveSupport::Duration.build(custom_value).inspect
    end
  end
end
