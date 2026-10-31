# frozen_string_literal: true

require "delegate"
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
      media_metadata_missing
      attachment_missing
    ].freeze
    METADATA_KEYS = %i[duration].freeze

    # Durations are rendered like ActiveSupport::Duration#inspect
    # ("1 minute and 30 seconds") but through the active_storage_validations.duration
    # I18n keys (units + sentence connectors) shipped in every bundled locale.
    # The English wording is the fallback for locales the gem does not ship.
    DURATION_UNITS = ActiveSupport::Duration::PARTS
    DEFAULT_DURATION_CONNECTORS = {
      words_connector: ", ",
      two_words_connector: " and ",
      last_word_connector: ", and "
    }.freeze

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

        # to_f, not to_i: durations are floats, and truncating would treat any
        # file shorter than a second as unanalyzable.
        if duration.to_f <= 0
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

    # Analyzer precision is milliseconds. `end - 1` on a Duration is 1 second.
    def exclusive_range_step
      0.001.seconds
    end

    def format_bound_value(value)
      return nil unless value

      # Encoder padding makes fixture files 2.024s, 5.029s, … Error copy still
      # talks in tenths of a second; comparison uses the analyzer's millisecond value.
      rounded = value.to_f.round(1)
      custom_value = rounded == rounded.to_i ? rounded.to_i : rounded
      duration_in_words(ActiveSupport::Duration.build(custom_value))
    end

    def duration_in_words(duration)
      parts = duration.parts.presence || { seconds: duration.value.to_i }

      words = parts.sort_by { |unit, _count| DURATION_UNITS.index(unit) }.map do |unit, count|
        count = LocalizedCount.new(count) unless count.is_a?(Integer)
        I18n.t("active_storage_validations.duration.#{unit}", count: count, default: default_unit_translation(unit))
      end

      words.to_sentence(locale: false, **duration_connectors)
    end

    # A decimal count (1.5 seconds) must still pick the plural form as a
    # number, but its text follows the locale's decimal separator ("1,5" in
    # French), like number_to_human_size does for sizes. I18n interpolates
    # %{count} with #to_s.
    class LocalizedCount < SimpleDelegator
      def to_s
        ActiveSupport::NumberHelper.number_to_delimited(__getobj__)
      end

      # Plural rules (rails-i18n) may check `count.is_a?(Numeric)`.
      def is_a?(klass)
        super || __getobj__.is_a?(klass)
      end
      alias_method :kind_of?, :is_a?
    end
    private_constant :LocalizedCount

    def default_unit_translation(unit)
      { one: "%{count} #{unit.to_s.singularize}", other: "%{count} #{unit}" }
    end

    def duration_connectors
      I18n.t("active_storage_validations.duration.connectors", default: DEFAULT_DURATION_CONNECTORS)
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
