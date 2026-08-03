# frozen_string_literal: true

require_relative "shared/asv_active_storageable"
require_relative "shared/asv_analyzable"
require_relative "shared/asv_attachable"
require_relative "shared/asv_errorable"
require_relative "shared/asv_symbolizable"

module ActiveStorageValidations
  class WithAudioValidator < ActiveModel::EachValidator # :nodoc
    include ASVActiveStorageable
    include ASVAnalyzable
    include ASVAttachable
    include ASVErrorable
    include ASVSymbolizable

    ERROR_TYPES = %i[audio_missing audio_present].freeze
    METADATA_KEYS = %i[audio].freeze

    def validate_each(record, attribute, _value)
      return if no_attachments?(record, attribute)

      validate_changed_files_from_metadata(record, attribute, METADATA_KEYS)
    end

    private

    def is_valid?(record, attribute, attachable, metadata)
      expected_audio = options.fetch(:with, true)
      return if metadata&.fetch(:audio, false) == expected_audio

      errors_options = initialize_error_options(options, attachable)
      error_type = expected_audio ? :audio_missing : :audio_present
      add_error(record, attribute, error_type, **errors_options)
    end
  end
end
