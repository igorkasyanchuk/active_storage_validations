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
    DIMENSION_HASH_KEYS = %i[min max in].freeze

    def check_validity!
      ensure_at_least_one_validator_option
      ensure_dimension_option_validity
      ensure_dimension_in_option_validity
      ensure_min_max_option_validity
      ensure_min_max_not_combined_with_dimension
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

    # A misspelled or empty width / height Hash (`{ minimum: 1000 }`, `{}`) used
    # to load and validate nothing, and a bare Range (`width: 100..200`) was
    # compared as an exact width. Procs are evaluated per record and cannot be
    # checked here.
    def ensure_dimension_option_validity
      %i[width height].each do |dimension|
        next unless options.key?(dimension)

        value = options[dimension]
        next if value.is_a?(Numeric) || value.is_a?(Proc)

        unless value.is_a?(Hash)
          raise ArgumentError, "{ #{dimension}: value } value must be an Integer, a Proc or a Hash with :min, :max or :in (e.g. #{dimension}: { in: 100..200 })"
        end

        ensure_dimension_hash_validity(dimension, value)
      end
    end

    def ensure_dimension_hash_validity(dimension, value)
      if value.empty? || (value.keys - DIMENSION_HASH_KEYS).any?
        raise ArgumentError, "{ #{dimension}: { … } } only accepts :min, :max and :in (got #{value.keys.inspect})"
      end

      if value.key?(:in) && (value.key?(:min) || value.key?(:max))
        raise ArgumentError, "{ #{dimension}: { in: } } cannot be combined with :min / :max"
      end

      %i[min max].each do |bound|
        next unless value.key?(bound)
        next if value[bound].is_a?(Numeric) || value[bound].is_a?(Proc)

        raise ArgumentError, "{ #{dimension}: { #{bound}: value } } value must be an Integer or a Proc"
      end
    end

    # Top-level min / max overwrite the width / height bounds and skip their
    # own checks, so combining both silently dropped a bound.
    def ensure_min_max_not_combined_with_dimension
      return unless %i[min max].any? { |bound| options.key?(bound) }
      return unless %i[width height].any? { |dimension| options.key?(dimension) }

      raise ArgumentError, "{ min: } / { max: } cannot be combined with :width / :height (use width: { min:, max: } and height: { min:, max: } instead)"
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
      bound_present?(flat_options, :min) || bound_present?(flat_options, :max)
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
      return false unless bound_present?(flat_options, bound)

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
      limit = dimension_limit(flat_options, dimension, bound)
      return false if limit.nil?

      bound == :min ? metadata[dimension] < limit : metadata[dimension] > limit
    end

    # Integer 0 is a real bound (`width: { max: 0 }`). Truthiness would skip it.
    def dimension_limit(flat_options, dimension, bound)
      limits = flat_options[dimension]
      return unless limits.is_a?(Hash) && bound_present?(limits, bound)

      limits[bound]
    end

    def validate_width_height(record, attribute, metadata, flat_options, errors_options)
      %i[width height].each do |dimension|
        next unless bound_present?(flat_options, dimension)

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
      bound_present?(flat_options[dimension], :in)
    end

    def outside_range?(value, options)
      if bound_present?(options, :in)
        !options[:in].include?(value)
      else
        min_exceeded?(value, options) || max_exceeded?(value, options)
      end
    end

    def min_exceeded?(value, options)
      bound_present?(options, :min) && value < options[:min]
    end

    def max_exceeded?(value, options)
      bound_present?(options, :max) && value > options[:max]
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
        if flat_options[dimension].is_a?(Hash)
          if bound_present?(flat_options[dimension], :in)
            range = flat_options[dimension][:in]
            # Range#begin / #end never raise; a Proc may still return an unbounded range.
            # Exclusive ranges reject the end bound — error :max is the last included value.
            flat_options[dimension][:min] = range.begin
            flat_options[dimension][:max] = last_included_range_end(range)
          end
        end
      end

      %i[min max].each do |bound|
        if bound_present?(flat_options, bound)
          range = flat_options[bound]
          flat_options[:width] ||= {}
          flat_options[:height] ||= {}
          flat_options[:width][bound] = range.begin
          flat_options[:height][bound] = range.end
        end
      end

      flat_options
    end

    # Exclusive ranges (`400...600`) reject the end bound. Error messages must
    # advertise the last included value, not the excluded endpoint.
    def last_included_range_end(range)
      return range.end unless range.respond_to?(:exclude_end?) && range.exclude_end?

      range.end - 1
    end
  end
end
