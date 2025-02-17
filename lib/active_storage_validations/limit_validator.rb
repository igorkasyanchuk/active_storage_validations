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
      if flat_options[:max].present? && flat_options[:min].present?
        count >= flat_options[:min] && count <= flat_options[:max]
      elsif flat_options[:max].present?
        count <= flat_options[:max]
      elsif flat_options[:min].present?
        count >= flat_options[:min]
      end
    end

    def ensure_at_least_one_validator_option
      unless AVAILABLE_CHECKS.any? { |argument| options.key?(argument) }
        raise ArgumentError, "You must pass either :max or :min to the validator"
      end
    end

    def ensure_arguments_validity
      return true if min_max_are_proc? || min_or_max_is_proc_and_other_not_present?

      raise ArgumentError, "You must pass integers to :min and :max" if min_or_max_defined_and_not_integer?
      raise ArgumentError, "You must pass a higher value to :max than to :min" if min_higher_than_max?
    end

    def min_max_are_proc?
      options[:min]&.is_a?(Proc) && options[:max]&.is_a?(Proc)
    end

    def min_or_max_is_proc_and_other_not_present?
      (options[:min]&.is_a?(Proc) && options[:max].nil?) ||
        (options[:min].nil? && options[:max]&.is_a?(Proc))
    end

    def min_or_max_defined_and_not_integer?
      (options.key?(:min) && !options[:min].is_a?(Integer)) ||
        (options.key?(:max) && !options[:max].is_a?(Integer))
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
      if flat_options[:min] && flat_options[:max]
        :limit_out_of_range
      elsif flat_options[:min] && count < flat_options[:min]
        :limit_min_not_reached
      else
        :limit_max_exceeded
      end
    end
  end
end
