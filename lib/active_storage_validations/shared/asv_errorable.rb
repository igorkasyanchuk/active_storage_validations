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
      record.errors.add(attribute, error_type, **blank_custom_message_values(record, attribute, errors_options), **errors_options)
    end

    private

    # A custom message is shared by every error type of the validator, which
    # do not all carry the same values: `message: "must be under %{max}"` on a
    # file that cannot be analyzed (media_metadata_missing) raised
    # I18n::MissingInterpolationArgument from errors.full_messages, a 500 on an
    # upload. The values an error does not carry are interpolated as blank.
    def blank_custom_message_values(record, attribute, errors_options)
      custom_message_templates(record, attribute, errors_options[:message])
        .flat_map { |template| template.scan(CUSTOM_MESSAGE_VALUE).flatten.compact }
        .map(&:to_sym).uniq
        .excluding(*I18n::RESERVED_KEYS, *RAILS_MESSAGE_VALUES, *errors_options.keys)
        .index_with(nil)
    end

    # A String message, or the translations of a Symbol one (an I18n key,
    # looked up like Rails does: the Symbol takes the place of the error type)
    # in every locale, since the message is rendered later, maybe in another.
    def custom_message_templates(record, attribute, message)
      return [ message ] if message.is_a?(String)
      return [] unless message.is_a?(Symbol)

      keys = custom_message_keys(record, attribute, message)
      I18n.available_locales.flat_map do |locale|
        translation = I18n.t(keys.first, default: [ *keys.drop(1), "" ], locale: locale)
        translation.is_a?(Hash) ? translation.values.grep(String) : Array(translation).grep(String)
      end
    end

    def custom_message_keys(record, attribute, message)
      klass = record.class
      keys = []
      if klass.respond_to?(:i18n_scope)
        attribute_key = attribute.to_s.remove(/\[\d+\]/)
        klass.lookup_ancestors.each do |ancestor|
          keys << :"#{klass.i18n_scope}.errors.models.#{ancestor.model_name.i18n_key}.attributes.#{attribute_key}.#{message}"
          keys << :"#{klass.i18n_scope}.errors.models.#{ancestor.model_name.i18n_key}.#{message}"
        end
        keys << :"#{klass.i18n_scope}.errors.messages.#{message}"
      end
      keys << :"errors.attributes.#{attribute}.#{message}"
      keys << :"errors.messages.#{message}"
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
