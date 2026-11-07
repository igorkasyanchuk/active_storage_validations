# frozen_string_literal: true

require_relative "../asv_attachable_adapter"

module ActiveStorageValidations
  module ASVErrorable
    extend ActiveSupport::Concern

    # Gem configuration options that are never error message data.
    CONFIGURATION_OPTIONS = %i[with in timeout spoofing_protection precision].freeze
    # Placeholders of a custom message (`%{max}` / `%<max>s`).
    CUSTOM_MESSAGE_VALUE = /%\{(\w+)\}|%<(\w+)>/
    # Values ActiveModel::Error#generate_message interpolates itself.
    RAILS_MESSAGE_VALUES = %i[attribute model value].freeze

    # Builds the options handed to +errors.add+. Like Rails' own validators
    # (LengthValidator::RESERVED_OPTIONS, NumericalityValidator#filtered_options)
    # the validator's check options (AVAILABLE_CHECKS) and the gem configuration
    # are left out: they may hold Procs or Ranges that would otherwise end up in
    # +errors.details+ and in the I18n interpolation arguments. Validators add
    # the resolved values their messages document (:min, :max, :count, …)
    # themselves. Rails options (:if, :on, :message, …) are forwarded as Rails
    # does; ActiveModel::Error#details strips them.
    def initialize_error_options(options, file = nil)
      curated_options = options.except(*CONFIGURATION_OPTIONS, *check_options)

      active_storage_validations_options = {
        validator_type: self.class.to_sym,
        custom_message: (options[:message] if options[:message].present?),
        filename: (get_filename(file) unless self.class.to_sym == :total_size)
      }.compact

      curated_options.merge(active_storage_validations_options)
    end

    # Every offending file gets its own error, so a has_many_attached relation
    # reports each invalid filename rather than only the first one.
    def add_error(record, attribute, error_type, **errors_options)
      # You can read https://api.rubyonrails.org/classes/ActiveModel/Errors.html#method-i-add
      # to better understand how Rails model errors work
      record.errors.add(attribute, error_type, **blank_custom_message_values(errors_options), **errors_options)
    end

    private

    # A custom message is shared by every error type of the validator, which
    # do not all carry the same values: `message: "must be under %{max}"` on a
    # file that cannot be analyzed (media_metadata_missing) raised
    # I18n::MissingInterpolationArgument from errors.full_messages, a 500 on an
    # upload. The values an error does not carry are interpolated as blank,
    # except raw options (`%{less_than}`), which keep raising: they are not
    # message values since 5.0 (see #initialize_error_options).
    def blank_custom_message_values(errors_options)
      message = errors_options[:message]
      return {} unless message.is_a?(String)

      message.scan(CUSTOM_MESSAGE_VALUE).flatten.compact.map(&:to_sym)
        .excluding(*I18n::RESERVED_KEYS, *RAILS_MESSAGE_VALUES, *raw_option_placeholders, *errors_options.keys)
        .index_with(nil)
    end

    # Overridden where a check option is also a documented message value.
    def raw_option_placeholders
      CONFIGURATION_OPTIONS + check_options
    end

    def check_options
      self.class.const_defined?(:AVAILABLE_CHECKS) ? self.class::AVAILABLE_CHECKS : []
    end

    def get_filename(file)
      return nil unless file

      filename_from(file)&.to_s.presence
    end

    def filename_from(file)
      ASVAttachableAdapter.filename_for(file)
    end
  end
end
