# frozen_string_literal: true

require_relative "shared/asv_active_storageable"
require_relative "shared/asv_analyzable"
require_relative "shared/asv_attachable"
require_relative "shared/asv_errorable"
require_relative "shared/asv_symbolizable"

module ActiveStorageValidations
  class ProcessableFileValidator < ActiveModel::EachValidator # :nodoc
    include ASVActiveStorageable
    include ASVAnalyzable
    include ASVAttachable
    include ASVErrorable
    include ASVSymbolizable

    ERROR_TYPES = %i[
      file_not_processable
    ].freeze
    METADATA_KEYS = %i[].freeze

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
  end
end
