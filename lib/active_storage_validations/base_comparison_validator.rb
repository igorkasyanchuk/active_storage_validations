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
      ensure_bound_validity(options) unless options[check_option].is_a?(Proc)
    end

    def validate_each(record, attribute, value)
      raise NotImplementedError
    end

    private

    # The one comparison option the validator was given (check_validity!
    # rejects zero or several).
    def check_option
      AVAILABLE_CHECKS.find { |check| options.key?(check) }
    end

    # Procs escape check_validity!: check what they return the same way. nil
    # means no bound (like limit's :min / :max), see #is_valid?.
    def set_flat_options(record)
      flat_options = super
      ensure_bound_validity(flat_options, from_proc: true) if options[check_option].is_a?(Proc)
      flat_options
    end

    # A non-number used to boot then raise from valid? (`less_than: "2MB"`); a
    # static negative bound or reversed / empty range rejected every file.
    #
    # A Proc result is data, not configuration: only a non-number raises. A
    # negative or reversed bound (a quota the record is already over) fails the
    # file with the usual error, as in 4.x.
    def ensure_bound_validity(flat_options, from_proc: false)
      bound = flat_options[check_option]
      return if bound.nil? && from_proc

      if check_option == :between
        return if valid_range_bound?(bound, from_proc)

        requirement = from_proc ? "a Range of numbers" : "a Range of non-negative numbers, whose begin is not greater than its end,"
      else
        return if valid_bound?(bound, from_proc)

        requirement = from_proc ? "a number" : "a non-negative number"
      end

      raise ArgumentError, "You must pass #{requirement} to :#{check_option} (got #{bound.inspect}#{' from a Proc' if from_proc})"
    end

    # ActiveSupport::Duration is a Numeric too.
    def valid_bound?(value, from_proc = false)
      value.is_a?(Numeric) && (from_proc || !value.negative?)
    end

    # A Proc may return a one-sided range (static ones are rejected at boot by
    # #ensure_between_range_is_bounded!).
    def valid_range_bound?(range, from_proc = false)
      return false unless range.is_a?(Range)

      bounds = [ range.begin, range.end ].compact
      return false unless bounds.all? { |bound| valid_bound?(bound, from_proc) }
      return true if from_proc || bounds.size < 2

      range.exclude_end? ? range.begin < range.end : range.begin <= range.end
    end

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

      # Integer 0 is a real bound (`equal_to: 0`), only nil (a Proc returning
      # nil) means no bound. It used to fail every file with a blank bound in
      # the message, while limit already accepted them.
      bound = flat_options[check_option]
      return true if bound.nil?

      case check_option
      when :between then bound.include?(value)
      when :less_than then value < bound
      when :less_than_or_equal_to then value <= bound
      when :greater_than then value > bound
      when :greater_than_or_equal_to then value >= bound
      when :equal_to then value == bound
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
