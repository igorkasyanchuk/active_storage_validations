# frozen_string_literal: true

require_relative 'concerns/errorable.rb'
require_relative 'concerns/symbolizable.rb'

module ActiveStorageValidations
  class BaseSizeValidator < ActiveModel::EachValidator # :nodoc:
    include OptionProcUnfolding
    include Errorable
    include Symbolizable

    delegate :number_to_human_size, to: ActiveSupport::NumberHelper

    AVAILABLE_CHECKS = %i[
      less_than
      less_than_or_equal_to
      greater_than
      greater_than_or_equal_to
      between
    ].freeze

    def initialize(*args)
      if self.class == BaseSizeValidator
        raise NotImplementedError, 'BaseSizeValidator is an abstract class and cannot be instantiated directly.'
      end
      super
    end

    def check_validity!
      unless AVAILABLE_CHECKS.one? { |argument| options.key?(argument) }
        raise ArgumentError, 'You must pass either :less_than(_or_equal_to), :greater_than(_or_equal_to), or :between to the validator'
      end
    end

    private

    def is_valid?(size, flat_options)
      return false if size < 0

      if flat_options[:between].present?
        flat_options[:between].include?(size)
      elsif flat_options[:less_than].present?
        size < flat_options[:less_than]
      elsif flat_options[:less_than_or_equal_to].present?
        size <= flat_options[:less_than_or_equal_to]
      elsif flat_options[:greater_than].present?
        size > flat_options[:greater_than]
      elsif flat_options[:greater_than_or_equal_to].present?
        size >= flat_options[:greater_than_or_equal_to]
      end
    end

    def populate_error_options(errors_options, flat_options)
      errors_options[:min_size] = number_to_human_size(min_size(flat_options))
      errors_options[:max_size] = number_to_human_size(max_size(flat_options))
    end

    def min_size(flat_options)
      flat_options[:between]&.min || flat_options[:greater_than] || flat_options[:greater_than_or_equal_to]
    end

    def max_size(flat_options)
      flat_options[:between]&.max || flat_options[:less_than] || flat_options[:less_than_or_equal_to]
    end
  end
end
