module ActiveStorageValidations
  class LimitValidator < ActiveModel::EachValidator
    AVAILABLE_CHECKS = [:max, :min]

    def check_validity!
      unless (AVAILABLE_CHECKS).any? { |argument| options.has_key?(argument) }
        raise ArgumentError, "You must pass either :max or :min to the validator"
      end
    end

    def validate_each(record, attribute, value)
      files = record.send(attribute)

      files = Array.wrap(files)

      errors_options = {}
      errors_options[:min] = options[:min]
      errors_options[:max] = options[:max]

      unless files_count_valid?(files.count)
        record.errors.add(attribute, options[:message].presence || :limit_out_of_range, errors_options)
        return
      end
    end

    def files_count_valid?(count)
      case
        when options[:max].present? && options[:min].present?
          count >= options[:min] && count <= options[:max]
        when options[:max].present?
          count <= options[:max]
        when options[:min].present?
          count >= options[:min]
      end
    end
  end
end
