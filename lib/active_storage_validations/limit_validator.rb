# frozen_string_literal: true

module ActiveStorageValidations
  class LimitValidator < ActiveModel::EachValidator # :nodoc:
    AVAILABLE_CHECKS = %i[max min].freeze

    def check_validity!
      return true if AVAILABLE_CHECKS.any? { |argument| options.key?(argument) }

      raise ArgumentError, 'You must pass either :max or :min to the validator'
    end

    def validate_each(record, attribute, _value)
      return true unless record.send(attribute).attached?

      files = Array.wrap(record.send(attribute))

      errors_options = {}
      errors_options[:min] = options[:min]
      errors_options[:max] = options[:max]

      return true if files_count_valid?(files.count)

      record.errors.add(attribute, options[:message].presence || :limit_out_of_range, errors_options)
    end

    def files_count_valid?(count)
      if options[:max].present? && options[:min].present?
        count >= options[:min] && count <= options[:max]
      elsif options[:max].present?
        count <= options[:max]
      elsif options[:min].present?
        count >= options[:min]
      end
    end
  end
end
