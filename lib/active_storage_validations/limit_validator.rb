# frozen_string_literal: true

module ActiveStorageValidations
  class LimitValidator < ActiveModel::EachValidator # :nodoc:
    include OptionProcUnfolding

    AVAILABLE_CHECKS = %i[max min].freeze

    def check_validity!
      return true if AVAILABLE_CHECKS.any? { |argument| options.key?(argument) }
      raise ArgumentError, 'You must pass either :max or :min to the validator'
    end

    def validate_each(record, attribute, _)
      files = Array.wrap(record.send(attribute)).compact.uniq
      flat_options = unfold_procs(record, self.options, AVAILABLE_CHECKS)
      errors_options = { min: flat_options[:min], max: flat_options[:max] }

      return true if files_count_valid?(files.count, flat_options)
      record.errors.add(attribute, options[:message].presence || :limit_out_of_range, **errors_options)
    end

    def files_count_valid?(count, flat_options)
      if flat_options[:max].present? && flat_options[:min].present?
        count >= flat_options[:min] && count <= flat_options[:max]
      elsif flat_options[:max].present?
        count <= flat_options[:max]
      elsif flat_options[:min].present?
        count >= flat_options[:min]
      end
    end
  end
end
