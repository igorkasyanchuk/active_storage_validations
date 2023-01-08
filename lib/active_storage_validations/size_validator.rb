# frozen_string_literal: true

module ActiveStorageValidations
  class SizeValidator < ActiveModel::EachValidator # :nodoc:
    include OptionProcUnfolding

    delegate :number_to_human_size, to: ActiveSupport::NumberHelper

    AVAILABLE_CHECKS = %i[less_than less_than_or_equal_to greater_than greater_than_or_equal_to between].freeze

    def check_validity!
      return true if AVAILABLE_CHECKS.any? { |argument| options.key?(argument) }
      raise ArgumentError, 'You must pass either :less_than(_or_equal_to), :greater_than(_or_equal_to), or :between to the validator'
    end

    def validate_each(record, attribute, _value)
      # only attached
      return true unless record.send(attribute).attached?

      files = Array.wrap(record.send(attribute))

      errors_options = {}
      errors_options[:message] = options[:message] if options[:message].present?
      flat_options = unfold_procs(record, self.options, AVAILABLE_CHECKS)

      files.each do |file|
        next if content_size_valid?(file.blob.byte_size, flat_options)

        errors_options[:file_size] = number_to_human_size(file.blob.byte_size)
        errors_options[:min_size] = number_to_human_size(min_size(flat_options))
        errors_options[:max_size] = number_to_human_size(max_size(flat_options))

        record.errors.add(attribute, :file_size_out_of_range, **errors_options)
        break
      end
    end

    def content_size_valid?(file_size, flat_options)
      if flat_options[:between].present?
        flat_options[:between].include?(file_size)
      elsif flat_options[:less_than].present?
        file_size < flat_options[:less_than]
      elsif flat_options[:less_than_or_equal_to].present?
        file_size <= flat_options[:less_than_or_equal_to]
      elsif flat_options[:greater_than].present?
        file_size > flat_options[:greater_than]
      elsif flat_options[:greater_than_or_equal_to].present?
        file_size >= flat_options[:greater_than_or_equal_to]
      end
    end

    def min_size(flat_options)
      flat_options[:between]&.min || flat_options[:greater_than] || flat_options[:greater_than_or_equal_to]
    end

    def max_size(flat_options)
      flat_options[:between]&.max || flat_options[:less_than] || flat_options[:less_than_or_equal_to]
    end
  end
end
