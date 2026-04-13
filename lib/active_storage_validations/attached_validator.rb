# frozen_string_literal: true

require_relative "shared/asv_active_storageable"
require_relative "shared/asv_errorable"
require_relative "shared/asv_orchestrable"
require_relative "shared/asv_symbolizable"

module ActiveStorageValidations
  class AttachedValidator < ActiveModel::EachValidator # :nodoc:
    include ASVActiveStorageable
    include ASVErrorable
    include ASVOrchestrable
    include ASVSymbolizable

    ERROR_TYPES = %i[blank].freeze
    FORBIDDEN_RAILS_OPTIONS = %i[allow_blank allow_nil].freeze

    def self.heavyweight?(_options); false; end

    def check_validity!
      ensure_options_validity
      ensure_no_allow_nil_or_blank_options
    end

    def validate_each(record, attribute, _value)
      return if attachments_present?(record, attribute) &&
                will_have_attachments_after_save?(record, attribute)

      errors_options = initialize_error_options(options)
      add_error(record, attribute, ERROR_TYPES.first, **errors_options)
    end

    private

    def ensure_options_validity
      custom_options = options.except(*ActiveStorageValidations::RAILS_VALIDATOR_OPTIONS)

      return if custom_options.empty?

      if custom_options.keys == [ :with ] && valid_with_value?(custom_options[:with])
        return
      end

      raise ArgumentError, error_message_invalid_options
    end

    def valid_with_value?(value)
      value == true || value.is_a?(Proc)
    end

    def error_message_invalid_options
      "You must pass either `true` or `{ with: true/Proc }`"
    end

    def ensure_no_allow_nil_or_blank_options
      FORBIDDEN_RAILS_OPTIONS.each do |forbidden_option|
        if options.key?(forbidden_option)
          raise ArgumentError, error_message_forbidden_option(forbidden_option)
        end
      end
    end

    def error_message_forbidden_option(forbidden_option)
      "You cannot pass the :#{forbidden_option} option to the #{self.class.to_sym} validator"
    end
  end
end
