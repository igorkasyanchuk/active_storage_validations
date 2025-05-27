# frozen_string_literal: true

require_relative "shared/asv_active_storageable"
require_relative "shared/asv_errorable"
require_relative "shared/asv_optionable"
require_relative "shared/asv_symbolizable"

module ActiveStorageValidations
  class BaseComparisonValidator < ActiveModel::EachValidator # :nodoc:
    include ASVActiveStorageable
    include ASVErrorable
    include ASVOptionable
    include ASVSymbolizable

    AVAILABLE_CHECKS = %i[
      less_than
      less_than_or_equal_to
      greater_than
      greater_than_or_equal_to
      between
      equal_to
    ].freeze

    def initialize(*args)
      if self.class == BaseComparisonValidator
        raise NotImplementedError, "BaseComparisonValidator is an abstract class and cannot be instantiated directly."
      end
      super
    end

    def check_validity!
      unless AVAILABLE_CHECKS.one? { |argument| options.key?(argument) }
        raise ArgumentError, "You must pass either :less_than(_or_equal_to), :greater_than(_or_equal_to), :between or :equal_to to the validator"
      end
    end

    def validate_each(record, attribute, value)
      raise NotImplementedError
    end

    private

    def is_valid?(value, flat_options)
      return false if value < 0

      if flat_options[:between].present?
        flat_options[:between].include?(value)
      elsif flat_options[:less_than].present?
        value < flat_options[:less_than]
      elsif flat_options[:less_than_or_equal_to].present?
        value <= flat_options[:less_than_or_equal_to]
      elsif flat_options[:greater_than].present?
        value > flat_options[:greater_than]
      elsif flat_options[:greater_than_or_equal_to].present?
        value >= flat_options[:greater_than_or_equal_to]
      elsif flat_options[:equal_to].present?
        value == flat_options[:equal_to]
      end
    end

    def populate_error_options(errors_options, flat_options)
      errors_options[:min] = format_bound_value(min(flat_options))
      errors_options[:exact] = format_bound_value(exact(flat_options))
      errors_options[:max] = format_bound_value(max(flat_options))
    end

    def format_bound_value
      raise NotImplementedError
    end

    def min(flat_options)
      flat_options[:between]&.min || flat_options[:greater_than] || flat_options[:greater_than_or_equal_to]
    end

    def exact(flat_options)
      flat_options[:equal_to]
    end

    def max(flat_options)
      flat_options[:between]&.max || flat_options[:less_than] || flat_options[:less_than_or_equal_to]
    end
  end
end
