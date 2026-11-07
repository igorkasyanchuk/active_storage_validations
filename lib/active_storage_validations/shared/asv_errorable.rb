# frozen_string_literal: true

require_relative "../asv_attachable_adapter"

module ActiveStorageValidations
  module ASVErrorable
    extend ActiveSupport::Concern

    # Placeholders of a custom message (`%{max}` / `%<max>s`).
    CUSTOM_MESSAGE_VALUE = /%\{(\w+)\}|%<(\w+)>/
    # Values ActiveModel::Error#generate_message interpolates itself.
    RAILS_MESSAGE_VALUES = %i[attribute model value].freeze

    def initialize_error_options(options, file = nil)
      not_explicitly_written_options = %i[with in]
      curated_options = options.except(*not_explicitly_written_options)

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
    # upload. The values an error does not carry are interpolated as blank.
    def blank_custom_message_values(errors_options)
      message = errors_options[:message]
      return {} unless message.is_a?(String)

      message.scan(CUSTOM_MESSAGE_VALUE).flatten.compact.map(&:to_sym)
        .excluding(*I18n::RESERVED_KEYS, *RAILS_MESSAGE_VALUES, *errors_options.keys)
        .index_with(nil)
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
