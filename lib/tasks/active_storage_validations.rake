# frozen_string_literal: true

namespace :active_storage_validations do
  desc "Clear the metadata cached on blobs (asv_* keys) so files are analyzed again. " \
       "CONTENT_TYPE=video/webm,image/png narrows it to these content types."
  task remove_metadata: :environment do
    blobs = ActiveStorage::Blob.all
    content_types = ENV.fetch("CONTENT_TYPE", "").split(",").map(&:strip).reject(&:empty?)
    blobs = blobs.where(content_type: content_types) if content_types.any?

    count = ActiveStorageValidations.remove_metadata!(blobs)
    puts "Cleared the active_storage_validations metadata of #{count} blob(s)."
  end
end
