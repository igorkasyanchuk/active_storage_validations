require_relative '../metadata'

module ActiveStorageValidations
  # ActiveStorageValidations::Metadatable
  #
  # Validator methods for analyzing the attachment metadata.
  module Metadatable
    extend ActiveSupport::Concern

    private

    # Loop through the newly submitted attachables to validate them
    def validate_changed_files_from_metadata(record, attribute)
      attachables_from_changes(record, attribute).each do |attachable|
        is_valid?(record, attribute, attachable, Metadata.new(attachable).metadata)
      end
    end

    # Retrieve an array of newly submitted attachables which are file
    # representations such as ActiveStorage::Blob, ActionDispatch::Http::UploadedFile,
    # Rack::Test::UploadedFile, Hash, String, File or Pathname
    def attachables_from_changes(record, attribute)
      changes = record.attachment_changes[attribute.to_s]
      return [] if changes.blank?

      Array.wrap(
        changes.is_a?(ActiveStorage::Attached::Changes::CreateMany) ? changes.attachables : changes.attachable
      )
    end
  end
end
