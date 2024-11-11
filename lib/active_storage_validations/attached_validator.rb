# frozen_string_literal: true

require_relative 'shared/active_storageable'
require_relative 'shared/errorable'
require_relative 'shared/symbolizable'

module ActiveStorageValidations
  class AttachedValidator < ActiveModel::EachValidator # :nodoc:
    include ActiveStorageable
    include Errorable
    include Symbolizable

    ERROR_TYPES = %i[blank].freeze

    def check_validity!
      %i[allow_nil allow_blank].each do |not_authorized_option|
        if options.include?(not_authorized_option)
          raise ArgumentError, "You cannot pass the :#{not_authorized_option} option to the #{self.class.to_sym} validator"
        end
      end
    end

    def validate_each(record, attribute, _value)
      return if attachments_present?(record, attribute) &&
                will_have_attachments_after_save?(record, attribute)

      errors_options = initialize_error_options(options)
      add_error(record, attribute, ERROR_TYPES.first, **errors_options)
    end
  end
end
