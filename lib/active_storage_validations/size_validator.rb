# frozen_string_literal: true

module ActiveStorageValidations
  class SizeValidator < ActiveModel::EachValidator # :nodoc:
    delegate :number_to_human_size, to: ActiveSupport::NumberHelper

    AVAILABLE_CHECKS = %i[less_than less_than_or_equal_to greater_than greater_than_or_equal_to between].freeze

    def check_validity!
      return true if AVAILABLE_CHECKS.any? { |argument| options.key?(argument) }

      raise ArgumentError, 'You must pass either :less_than, :greater_than, or :between to the validator'
    end

    def validate_each(record, attribute, _value)
      # only attached
      return true unless record.send(attribute).attached?

      files = Array.wrap(record.send(attribute))

      errors_options = {}
      errors_options[:message] = options[:message] if options[:message].present?

      files.each do |file|
        next if content_size_valid?(file.blob.byte_size)

        errors_options[:file_size] = number_to_human_size(file.blob.byte_size)
        errors_options[:min_size] = number_to_human_size(min_size)
        errors_options[:max_size] = number_to_human_size(max_size)

        record.errors.add(attribute, :file_size_out_of_range, **errors_options)
        break
      end
    end

    def content_size_valid?(file_size)
      if options[:between].present?
        options[:between].include?(file_size)
      elsif options[:less_than].present?
        file_size < options[:less_than]
      elsif options[:less_than_or_equal_to].present?
        file_size <= options[:less_than_or_equal_to]
      elsif options[:greater_than].present?
        file_size > options[:greater_than]
      elsif options[:greater_than_or_equal_to].present?
        file_size >= options[:greater_than_or_equal_to]
      end
    end

    def min_size
      options[:between]&.min || options[:greater_than] || options[:greater_than_or_equal_to]
    end

    def max_size
      options[:between]&.max || options[:less_than] || options[:less_than_or_equal_to]
    end
  end
end
