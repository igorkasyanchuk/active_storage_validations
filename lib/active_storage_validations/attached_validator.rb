# frozen_string_literal: true

require_relative 'concerns/errorable.rb'
require_relative 'concerns/symbolizable.rb'

module ActiveStorageValidations
  class AttachedValidator < ActiveModel::EachValidator # :nodoc:
    include Errorable
    include Symbolizable

    ERROR_TYPES = %i[blank].freeze

    def check_validity!
      %i[allow_nil allow_blank].each do |not_authorized_option|
        if options.include?(not_authorized_option)
          raise ArgumentError, "You cannot pass the :#{not_authorized_option} option to the #{self.class.name.split('::').last.underscore}"
        end
      end
    end

    def validate_each(record, attribute, _value)
      return if record.send(attribute).attached? &&
                !Array.wrap(record.send(attribute)).all?(&:marked_for_destruction?)

      errors_options = initialize_error_options(options)
      add_error(record, attribute, ERROR_TYPES.first, **errors_options)
    end
  end
end
