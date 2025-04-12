# frozen_string_literal: true

require_relative "shared/asv_active_storageable"
require_relative "shared/asv_analyzable"
require_relative "shared/asv_attachable"
require_relative "shared/asv_errorable"
require_relative "shared/asv_optionable"
require_relative "shared/asv_symbolizable"

module ActiveStorageValidations
  class DimensionValidator < ActiveModel::EachValidator # :nodoc
    include ASVActiveStorageable
    include ASVAnalyzable
    include ASVAttachable
    include ASVErrorable
    include ASVOptionable
    include ASVSymbolizable

    AVAILABLE_CHECKS = %i[width height min max].freeze
    ERROR_TYPES = %i[
      dimension_min_not_included_in
      dimension_max_not_included_in
      dimension_width_not_included_in
      dimension_height_not_included_in
      dimension_width_not_greater_than_or_equal_to
      dimension_height_not_greater_than_or_equal_to
      dimension_width_not_less_than_or_equal_to
      dimension_height_not_less_than_or_equal_to
      dimension_width_not_equal_to
      dimension_height_not_equal_to
      media_metadata_missing
    ].freeze
    METADATA_KEYS = %i[width height].freeze

    def check_validity!
      ensure_at_least_one_validator_option
      ensure_dimension_in_option_validity
      ensure_min_max_option_validity
    end

    def validate_each(record, attribute, _value)
      return if no_attachments?(record, attribute)

      validate_changed_files_from_metadata(record, attribute, METADATA_KEYS)
    end

    private

    def ensure_at_least_one_validator_option
      unless AVAILABLE_CHECKS.any? { |argument| options.key?(argument) }
        raise ArgumentError, "You must pass either :width, :height, :min or :max to the validator"
      end
    end

    def ensure_dimension_in_option_validity
      %i[width height].each do |dimension|
        if options[dimension]&.is_a?(Hash) && options[dimension][:in].present?
          raise ArgumentError, "{ #{dimension}: { in: value } } value must be a Range (min..max)" if !options[dimension][:in].is_a?(Range) && !options[dimension][:in].is_a?(Proc)
        end
      end
    end

    def ensure_min_max_option_validity
      %i[min max].each do |bound|
        if options[bound].present?
          raise ArgumentError, "{ #{bound}: value } value must be a Range (#{bound}_width..#{bound}_height)" if !options[bound]&.is_a?(Range) && !options[bound]&.is_a?(Proc)
        end
      end
    end

    def is_valid?(record, attribute, file, metadata)
      flat_options = process_options(record)
      errors_options = initialize_error_options(options, file)

      return add_media_metadata_missing_error(record, attribute, file, errors_options) unless valid_metadata?(metadata)

      if min_max_validation?(flat_options)
        validate_min_max(record, attribute, metadata, flat_options, errors_options)
      else
        validate_width_height(record, attribute, metadata, flat_options, errors_options)
      end
    end

    def valid_metadata?(metadata)
      metadata[:width].to_i > 0 && metadata[:height].to_i > 0
    end

    def min_max_validation?(flat_options)
      flat_options[:min] || flat_options[:max]
    end

    def validate_min_max(record, attribute, metadata, flat_options, errors_options)
      return false unless validate_min(record, attribute, metadata, flat_options, errors_options)
      return false unless validate_max(record, attribute, metadata, flat_options, errors_options)

      true
    end

    def validate_width_height(record, attribute, metadata, flat_options, errors_options)
      %i[width height].each do |dimension|
        next unless flat_options[dimension]

        if flat_options[dimension].is_a?(Hash)
          validate_range(record, attribute, dimension, metadata, flat_options, errors_options)
        else
          validate_exact(record, attribute, dimension, metadata, flat_options, errors_options)
        end
      end
    end

    # rubocop:disable Metrics/BlockLength
    %i[min max].each do |bound|
      define_method("validate_#{bound}") do |record, attribute, metadata, flat_options, errors_options|
        if send(:"invalid_#{bound}?", flat_options, metadata)
          send(:"add_#{bound}_error", record, attribute, flat_options, errors_options)
          false
        else
          true
        end
      end

      define_method("validate_dimension_#{bound}") do |record, attribute, dimension, metadata, flat_options, errors_options|
        if send(:"invalid_dimension_#{bound}?", flat_options, dimension, metadata)
          send(:"add_dimension_#{bound}_error", record, attribute, dimension, flat_options, errors_options)
          false
        else
          true
        end
      end

      define_method("invalid_#{bound}?") do |flat_options, metadata|
        flat_options[bound] && (
          send(:"invalid_dimension_#{bound}?", flat_options, :width, metadata) ||
          send(:"invalid_dimension_#{bound}?", flat_options, :height, metadata)
        )
      end

      define_method("invalid_dimension_#{bound}?") do |flat_options, dimension, metadata|
        flat_options[dimension][bound] && metadata[dimension].public_send(bound == :min ? :< : :>, flat_options[dimension][bound])
      end

      define_method("add_#{bound}_error") do |record, attribute, flat_options, errors_options|
        errors_options[:width] = flat_options[:width][bound]
        errors_options[:height] = flat_options[:height][bound]
        add_error(record, attribute, :"dimension_#{bound}_not_included_in", **errors_options)
      end

      define_method("add_dimension_#{bound}_error") do |record, attribute, dimension, flat_options, errors_options|
        error_type = bound == :min ? :not_greater_than_or_equal_to : :not_less_than_or_equal_to
        errors_options[:length] = flat_options[dimension][bound]
        add_error(record, attribute, :"dimension_#{dimension}_#{error_type}", **errors_options)
      end
    end
    # rubocop:enable Metrics/BlockLength

    def validate_range(record, attribute, dimension, metadata, flat_options, errors_options)
      if in_option_used?(flat_options, dimension)
        return false unless validate_in(record, attribute, dimension, metadata, flat_options, errors_options)
      else
        return false unless validate_dimension_min_max(record, attribute, dimension, metadata, flat_options, errors_options)
      end

      true
    end

    def validate_in(record, attribute, dimension, metadata, flat_options, errors_options)
      if outside_range?(metadata[dimension], flat_options[dimension])
        add_range_error(record, attribute, dimension, flat_options, errors_options)
        false
      else
        true
      end
    end

    def in_option_used?(flat_options, dimension)
      flat_options[dimension][:in]
    end

    def outside_range?(value, options)
      value < options[:min] || value > options[:max]
    end

    def add_range_error(record, attribute, dimension, flat_options, errors_options)
      errors_options[:min] = flat_options[dimension][:min]
      errors_options[:max] = flat_options[dimension][:max]
      add_error(record, attribute, :"dimension_#{dimension}_not_included_in", **errors_options)
    end

    def validate_dimension_min_max(record, attribute, dimension, metadata, flat_options, errors_options)
      %i[min max].each do |bound|
        send(:"validate_dimension_#{bound}", record, attribute, dimension, metadata, flat_options, errors_options)
      end
    end

    def validate_exact(record, attribute, dimension, metadata, flat_options, errors_options)
      if metadata[dimension] != flat_options[dimension]
        errors_options[:length] = flat_options[dimension]
        add_error(record, attribute, :"dimension_#{dimension}_not_equal_to", **errors_options)
        false
      else
        true
      end
    end

    def process_options(record)
      flat_options = set_flat_options(record)

      %i[width height].each do |dimension|
        if flat_options[dimension] and flat_options[dimension].is_a?(Hash)
          if (range = flat_options[dimension][:in])
            flat_options[dimension][:min], flat_options[dimension][:max] = range.min, range.max
          end
        end
      end

      %i[min max].each do |bound|
        if (range = flat_options[bound])
          flat_options[:width] = { bound => range.first }
          flat_options[:height] = { bound => range.last }
        end
      end

      flat_options
    end
  end
end
