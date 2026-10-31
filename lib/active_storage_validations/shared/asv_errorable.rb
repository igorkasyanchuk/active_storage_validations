# frozen_string_literal: true

require_relative "../asv_attachable_adapter"

module ActiveStorageValidations
  module ASVErrorable
    extend ActiveSupport::Concern

    # Gem configuration options that are never error message data.
    CONFIGURATION_OPTIONS = %i[with in timeout spoofing_protection].freeze

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
      record.errors.add(attribute, error_type, **errors_options)
    end

    private

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
