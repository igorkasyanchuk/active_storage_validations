# frozen_string_literal: true

module ActiveStorageValidations
  class AttachedValidator < ActiveModel::EachValidator # :nodoc:
    def validate_each(record, attribute, _value)
      return if record.send(attribute).attached?

      errors_options = {}
      errors_options[:message] = options[:message] if options[:message].present?

      record.errors.add(attribute, :blank, **errors_options)
    end
  end
end
