# frozen_string_literal: true

module ActiveStorageValidations
  class AttachedValidator < ActiveModel::EachValidator # :nodoc:
    def validate_each(record, attribute, _value)
      return if record.send(attribute).attached?

      record.errors.add(attribute, :blank)
    end
  end
end
