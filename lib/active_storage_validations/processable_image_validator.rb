# frozen_string_literal: true

require_relative 'shared/active_storageable'
require_relative 'shared/attachable'
require_relative 'shared/errorable'
require_relative 'shared/symbolizable'

module ActiveStorageValidations
  class ProcessableImageValidator < ActiveModel::EachValidator # :nodoc
    include ActiveStorageable
    include Attachable
    include Errorable
    include Symbolizable

    ERROR_TYPES = %i[
      image_not_processable
    ].freeze

    def validate_each(record, attribute, _value)
      return if no_attachments?(record, attribute)

      validate_changed_files_from_metadata(record, attribute)
    end

    private

    def is_valid?(record, attribute, attachable, metadata)
      return if !metadata.empty?

      errors_options = initialize_error_options(options, attachable)
      add_error(record, attribute, ERROR_TYPES.first , **errors_options)
    end
  end
end
