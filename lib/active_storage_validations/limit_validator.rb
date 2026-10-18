# frozen_string_literal: true

require_relative "shared/asv_active_storageable"
require_relative "shared/asv_errorable"
require_relative "shared/asv_optionable"
require_relative "shared/asv_symbolizable"

module ActiveStorageValidations
  class LimitValidator < ActiveModel::EachValidator # :nodoc:
    include ASVActiveStorageable
    include ASVErrorable
    include ASVOptionable
    include ASVSymbolizable

    AVAILABLE_CHECKS = %i[max min].freeze
    ERROR_TYPES = %i[
      limit_out_of_range
      limit_min_not_reached
      limit_max_exceeded
    ].freeze

    def check_validity!
      ensure_at_least_one_validator_option
      ensure_arguments_validity
    end

    def validate_each(record, attribute, _value)
      files = attached_files(record, attribute).reject(&:blank?)
      flat_options = set_flat_options(record)
      count = files.count

      return if files_count_valid?(count, flat_options)

      errors_options = initialize_and_populate_error_options(options, flat_options, count)
      error_type = set_error_type(flat_options, count)
      add_error(record, attribute, error_type, **errors_options)
    end

    private

    def files_count_valid?(count, flat_options)
      has_min = bound_present?(flat_options, :min)
      has_max = bound_present?(flat_options, :max)
      return true unless has_min || has_max

      (!has_min || count >= flat_options[:min]) &&
        (!has_max || count <= flat_options[:max])
    end

    def ensure_at_least_one_validator_option
      unless AVAILABLE_CHECKS.any? { |argument| options.key?(argument) }
        raise ArgumentError, "You must pass either :max or :min to the validator"
      end
    end

    def ensure_arguments_validity
      raise ArgumentError, "You must pass integers to :min and :max" unless bounds_are_integer_or_proc?
      raise ArgumentError, "You must pass a higher value to :max than to :min" if min_higher_than_max?
    end

    # A Proc is a deferred integer (`min: 1, max: -> { record.plan_limit }`).
    # Only static integers can be compared at boot.
    def bounds_are_integer_or_proc?
      AVAILABLE_CHECKS.all? { |bound| bound_is_integer_or_proc?(bound) }
    end

    def bound_is_integer_or_proc?(bound)
      !options.key?(bound) || options[bound].is_a?(Integer) || options[bound].is_a?(Proc)
    end

    def min_higher_than_max?
      options[:min] > options[:max] if options[:min].is_a?(Integer) && options[:max].is_a?(Integer)
    end

    def initialize_and_populate_error_options(options, flat_options, count)
      errors_options = initialize_error_options(options)
      errors_options[:min] = flat_options[:min]
      errors_options[:max] = flat_options[:max]
      errors_options[:count] = count
      errors_options
    end

    def set_error_type(flat_options, count)
      has_min = bound_present?(flat_options, :min)
      has_max = bound_present?(flat_options, :max)

      if has_min && has_max
        :limit_out_of_range
      elsif has_min && count < flat_options[:min]
        :limit_min_not_reached
      else
        :limit_max_exceeded
      end
    end
  end
end
