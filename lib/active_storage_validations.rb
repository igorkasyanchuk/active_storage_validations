# frozen_string_literal: true

require "active_model"
require "active_support/concern"
require "active_support/core_ext/module/attribute_accessors"

module ActiveStorageValidations
  # When true (default), FormBuilder#file_field automatically sets the HTML
  # +accept+ attribute from +content_type+ validators. Can also be overridden
  # per field with +infer_accept:+.
  mattr_accessor :infer_file_field_accept, instance_accessor: false, default: true
end

require "active_storage_validations/analyzer"
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
require "active_storage_validations/aspect_ratio_validator"
require "active_storage_validations/processable_file_validator"
require "active_storage_validations/size_validator"
require "active_storage_validations/total_size_validator"
require "active_storage_validations/pages_validator"

require "active_storage_validations/form_builder"
require "active_storage_validations/engine"
require "active_storage_validations/railtie"
