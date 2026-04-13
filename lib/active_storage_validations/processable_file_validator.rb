# frozen_string_literal: true

require_relative "shared/asv_active_storageable"
require_relative "shared/asv_analyzable"
require_relative "shared/asv_attachable"
require_relative "shared/asv_errorable"
require_relative "shared/asv_orchestrable"
require_relative "shared/asv_symbolizable"

module ActiveStorageValidations
  class ProcessableFileValidator < ActiveModel::EachValidator # :nodoc
    include ASVActiveStorageable
    include ASVAnalyzable
    include ASVAttachable
    include ASVErrorable
    include ASVOrchestrable
    include ASVSymbolizable

    ERROR_TYPES = %i[
      file_not_processable
    ].freeze
    METADATA_KEYS = %i[].freeze

    def self.heavyweight?(_options); true; end

    def check_validity!
      ensure_options_validity
    end

    def validate_each(record, attribute, _value)
      return if no_attachments?(record, attribute)

      validate_changed_files_from_metadata(record, attribute, METADATA_KEYS)
    end

    private

    def is_valid?(record, attribute, attachable, metadata)
      return if !metadata.empty?

      errors_options = initialize_error_options(options, attachable)
      add_error(record, attribute, ERROR_TYPES.first, **errors_options)
    end

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
  end
end
