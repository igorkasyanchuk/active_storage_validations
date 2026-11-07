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
  mattr_reader :command_timeout, instance_accessor: false, default: 10.seconds

  def self.command_timeout=(value)
    unless valid_command_timeout?(value)
      raise ArgumentError, "command_timeout must be a positive number of seconds, or nil to disable it (got #{value.inspect})"
    end

    @@command_timeout = value
  end

  # A deadline of 0 (or less) fails every analysis; a Proc cannot be resolved
  # since analyzers do not see the record.
  def self.valid_command_timeout?(value) # :nodoc:
    value.nil? || (value.is_a?(Numeric) && value.positive?)
  end

  def self.configure
    yield self
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
