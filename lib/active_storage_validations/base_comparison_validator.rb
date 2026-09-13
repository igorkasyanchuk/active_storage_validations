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

      ensure_between_range_is_bounded!
    end

    def validate_each(record, attribute, value)
      raise NotImplementedError
    end

    private

    # Endless / beginless ranges (`1.kilobyte..`, `..2.megabytes`) pass
    # Range#include? but raise RangeError from Range#min / #max the first time
    # an error message has to be built, i.e. on the first invalid record.
    # Procs are evaluated per record and cannot be checked here.
    def ensure_between_range_is_bounded!
      return unless options.key?(:between)

      between = options[:between]
      return if between.is_a?(Proc)
      return if between.is_a?(Range) && !between.begin.nil? && !between.end.nil?

      raise ArgumentError, "You must pass a Range with both bounds to :between (use :greater_than_or_equal_to or :less_than_or_equal_to for a single bound)"
    end

    def is_valid?(value, flat_options)
      return false if value < 0

      # Integer 0 is a real bound (`equal_to: 0`). `.present?` treats it as
      # absent, so the comparison would be skipped and every file would fail.
      if bound_present?(flat_options, :between)
        flat_options[:between].include?(value)
      elsif bound_present?(flat_options, :less_than)
        value < flat_options[:less_than]
      elsif bound_present?(flat_options, :less_than_or_equal_to)
        value <= flat_options[:less_than_or_equal_to]
      elsif bound_present?(flat_options, :greater_than)
        value > flat_options[:greater_than]
      elsif bound_present?(flat_options, :greater_than_or_equal_to)
        value >= flat_options[:greater_than_or_equal_to]
      elsif bound_present?(flat_options, :equal_to)
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

    # Range#begin / #end (rather than #min / #max) never raise, whatever the
    # range: a Proc may still return an unbounded or exclusive non-integer range.
    def min(flat_options)
      flat_options[:between]&.begin || flat_options[:greater_than] || flat_options[:greater_than_or_equal_to]
    end

    def exact(flat_options)
      flat_options[:equal_to]
    end

    def max(flat_options)
      if (range = flat_options[:between])
        last_included_range_end(range)
      else
        flat_options[:less_than] || flat_options[:less_than_or_equal_to]
      end
    end

    # Exclusive ranges (`1...5`) reject the end bound. Error messages must
    # advertise the last included value, not the excluded endpoint.
    def last_included_range_end(range)
      return range.end unless range.respond_to?(:exclude_end?) && range.exclude_end?

      range.end - exclusive_range_step
    end

    # Integer comparisons (bytes, pages) step by 1. Duration overrides this
    # so `7.seconds - 1` is not advertised as "6 seconds".
    def exclusive_range_step
      1
    end
  end
end
