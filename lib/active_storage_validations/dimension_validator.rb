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
        next unless options[dimension].is_a?(Hash) && options[dimension].key?(:in)

        in_option = options[dimension][:in]
        unless in_option.is_a?(Range) || in_option.is_a?(Proc)
          raise ArgumentError, "{ #{dimension}: { in: value } } value must be a Range (min..max)"
        end

        ensure_range_has_both_bounds!(
          in_option,
          "{ #{dimension}: { in: } } value must be a Range with both bounds (use #{dimension}: { min: } or #{dimension}: { max: } for a single bound)"
        )
      end
    end

    def ensure_min_max_option_validity
      %i[min max].each do |bound|
        next unless options[bound].present?

        unless options[bound].is_a?(Range) || options[bound].is_a?(Proc)
          raise ArgumentError, "{ #{bound}: value } value must be a Range (#{bound}_width..#{bound}_height)"
        end

        ensure_range_has_both_bounds!(
          options[bound],
          "{ #{bound}: } value must be a Range with both bounds (#{bound}_width..#{bound}_height)"
        )
      end
    end

    # Endless / beginless ranges (`100..`, `..800`) raise RangeError from
    # Range#min / #max. Procs are evaluated per record and cannot be checked here.
    def ensure_range_has_both_bounds!(value, message)
      return if value.is_a?(Proc)
      return if value.is_a?(Range) && !value.begin.nil? && !value.end.nil?

      raise ArgumentError, message
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

    # { min: 100..200, max: 800..600 } options: one error per violated bound,
    # reported on both dimensions (:width / :height) at once.
    def validate_min_max(record, attribute, metadata, flat_options, errors_options)
      %i[min max].all? { |bound| validate_bound(bound, record, attribute, metadata, flat_options, errors_options) }
    end

    def validate_bound(bound, record, attribute, metadata, flat_options, errors_options)
      return true unless invalid_bound?(bound, flat_options, metadata)

      errors_options[:width] = flat_options[:width][bound]
      errors_options[:height] = flat_options[:height][bound]
      add_error(record, attribute, :"dimension_#{bound}_not_included_in", **errors_options)
      false
    end

    def invalid_bound?(bound, flat_options, metadata)
      return false unless flat_options[bound]

      %i[width height].any? { |dimension| invalid_dimension_bound?(bound, dimension, flat_options, metadata) }
    end

    # { width: { min:, max: } } options: the error names the dimension and
    # carries the violated bound as :length.
    def validate_dimension_min_max(record, attribute, dimension, metadata, flat_options, errors_options)
      %i[min max].each do |bound|
        validate_dimension_bound(bound, record, attribute, dimension, metadata, flat_options, errors_options)
      end
    end

    def validate_dimension_bound(bound, record, attribute, dimension, metadata, flat_options, errors_options)
      return true unless invalid_dimension_bound?(bound, dimension, flat_options, metadata)

      errors_options[:length] = flat_options[dimension][bound]
      error_type = bound == :min ? :not_greater_than_or_equal_to : :not_less_than_or_equal_to
      add_error(record, attribute, :"dimension_#{dimension}_#{error_type}", **errors_options)
      false
    end

    def invalid_dimension_bound?(bound, dimension, flat_options, metadata)
      limit = flat_options[dimension][bound]
      return false unless limit

      bound == :min ? metadata[dimension] < limit : metadata[dimension] > limit
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
      if (range = options[:in])
        !range.include?(value)
      else
        min, max = options[:min], options[:max]
        (min && value < min) || (max && value > max)
      end
    end

    def add_range_error(record, attribute, dimension, flat_options, errors_options)
      errors_options[:min] = flat_options[dimension][:min]
      errors_options[:max] = flat_options[dimension][:max]
      add_error(record, attribute, :"dimension_#{dimension}_not_included_in", **errors_options)
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
            # Range#begin / #end never raise; a Proc may still return an unbounded range.
            flat_options[dimension][:min] = range.begin
            flat_options[dimension][:max] = range.end
          end
        end
      end

      %i[min max].each do |bound|
        if (range = flat_options[bound])
          flat_options[:width] ||= {}
          flat_options[:height] ||= {}
          flat_options[:width][bound] = range.begin
          flat_options[:height][bound] = range.end
        end
      end

      flat_options
    end
  end
end
