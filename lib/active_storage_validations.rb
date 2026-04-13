# frozen_string_literal: true

require "active_model"
require "active_support/concern"

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
require "active_storage_validations/attachment_validator"
require "active_storage_validations/content_type_validator"
require "active_storage_validations/limit_validator"
require "active_storage_validations/dimension_validator"
require "active_storage_validations/duration_validator"
require "active_storage_validations/aspect_ratio_validator"
require "active_storage_validations/processable_file_validator"
require "active_storage_validations/size_validator"
require "active_storage_validations/total_size_validator"
require "active_storage_validations/pages_validator"

require "active_storage_validations/deprecator"
require "active_storage_validations/engine"
require "active_storage_validations/railtie"


module ActiveStorageValidations
  extend ActiveSupport::Concern

  RAILS_VALIDATOR_OPTIONS = %i[allow_blank allow_nil if message on strict unless].freeze

  class_methods do
    # Declare Active Storage validations with a dedicated validator API.
    #
    # It behaves exactly like Rails `validates`, however this custom validator
    # allows to orchestrate between lightweight and heavyweight validators.
    #
    # Metadata validators, which are heavyweight validators, are short-circuited
    # when the size or content_type validator failed (lightweight validators).
    def validate_attached(*attributes, **options)
      validates_with AttachmentValidator, _merge_attributes(attributes).merge(options)
    end
  end
end
