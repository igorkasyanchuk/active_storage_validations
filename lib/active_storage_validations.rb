# frozen_string_literal: true

require "active_model"
require "active_support/concern"
require "active_support/core_ext/module/attribute_accessors"
require "active_support/core_ext/numeric/time"

module ActiveStorageValidations
  # When true (default), FormBuilder#file_field automatically sets the HTML
  # +accept+ attribute from +content_type+ validators. Can also be overridden
  # per field with +infer_accept:+.
  mattr_accessor :infer_file_field_accept, instance_accessor: false, default: true

  # Maximum time allowed for external analyzer commands (ffprobe, pdfinfo, file,
  # magika, MiniMagick, libvips). Set to +nil+ to disable. Per-validator +timeout:+
  # overrides this value for the analysis that validator triggers.
  mattr_accessor :command_timeout, instance_accessor: false, default: 10.seconds

  def self.configure
    yield self
  end

  # Clears the metadata the gem cached on saved blobs (their +asv_*+ custom
  # metadata keys) so their next validation analyzes the files again. A cached
  # value is trusted as is, including a value an analyzer could not extract:
  # run this after an upgrade that improves an analyzer. +blobs+ narrows the
  # blobs to clear (any ActiveStorage::Blob relation). Returns the number of
  # blobs updated. Other custom metadata is kept.
  #
  # The +metadata+ column is written directly, skipping the blob callbacks:
  # clearing a cache must not touch every attachment and attached record.
  #
  #   ActiveStorageValidations.remove_metadata!
  #   ActiveStorageValidations.remove_metadata!(ActiveStorage::Blob.where(content_type: "video/webm"))
  def self.remove_metadata!(blobs = ActiveStorage::Blob.all)
    blobs.find_each.count do |blob|
      next false if blob.active_storage_validations_metadata.empty?

      blob.update_column(:metadata, blob.metadata.merge("custom" => blob.custom_metadata.reject { |key, _| key.to_s.start_with?("asv_") }))
      true
    end
  end
end

require "active_storage_validations/analyzer"
require "active_storage_validations/analyzer/content_type_analyzer"
require "active_storage_validations/analyzer/content_type_analyzer/file"
require "active_storage_validations/analyzer/content_type_analyzer/magika"
require "active_storage_validations/analyzer/image_analyzer"
require "active_storage_validations/analyzer/image_analyzer/image_magick"
require "active_storage_validations/analyzer/image_analyzer/vips"
require "active_storage_validations/analyzer/null_analyzer"
require "active_storage_validations/analyzer/video_analyzer"
require "active_storage_validations/analyzer/audio_analyzer"
require "active_storage_validations/analyzer/pdf_analyzer"

require "active_storage_validations/extensors/asv_blob_metadatable"
require "active_storage_validations/extensors/asv_marcelable"

require "active_storage_validations/attached_validator"
require "active_storage_validations/content_type_validator"
require "active_storage_validations/limit_validator"
require "active_storage_validations/dimension_validator"
require "active_storage_validations/duration_validator"
require "active_storage_validations/with_audio_validator"
require "active_storage_validations/aspect_ratio_validator"
require "active_storage_validations/processable_file_validator"
require "active_storage_validations/size_validator"
require "active_storage_validations/total_size_validator"
require "active_storage_validations/pages_validator"

require "active_storage_validations/form_builder"
require "active_storage_validations/engine"
require "active_storage_validations/railtie"
