# frozen_string_literal: true

require_relative "base_comparison_validator"

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
      duration_not_equal_to
    ].freeze
    METADATA_KEYS = %i[duration].freeze

    def validate_each(record, attribute, _value)
      return if no_attachments?(record, attribute)

      flat_options = set_flat_options(record)

      attachables_and_blobs(record, attribute).each do |attachable, blob|
        duration = begin
          metadata_for(blob, attachable, METADATA_KEYS)&.fetch(:duration, nil)
        rescue ActiveStorage::FileNotFoundError
          add_attachment_missing_error(record, attribute, attachable)
          next
        end

        if duration.to_i <= 0
          add_media_metadata_missing_error(record, attribute, attachable)
          next
        end

        is_valid?(duration, flat_options) || populate_error_options_and_add_error(record, attribute, attachable, flat_options, duration)
      end
    end

    private

    def populate_error_options_and_add_error(record, attribute, attachable, flat_options, duration)
      errors_options = initialize_error_options(options, attachable)
      populate_error_options(errors_options, flat_options, duration)

      error_type = set_error_type(flat_options)

      add_error(record, attribute, error_type, **errors_options)
    end

    def format_bound_value(value)
      return nil unless value

      custom_value = value == value.to_i ? value.to_i : value
      ActiveSupport::Duration.build(custom_value).inspect
    end

    def populate_error_options(errors_options, flat_options, duration)
      super(errors_options, flat_options)
      errors_options[:duration] = format_bound_value(duration)
    end

    def set_error_type(flat_options)
      keys = AVAILABLE_CHECKS & flat_options.keys
      "duration_not_#{keys.first}".to_sym
    end
  end
end
