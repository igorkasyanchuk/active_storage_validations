# frozen_string_literal: true

module ActiveStorageValidations
  # ActiveStorageValidations::ASVAnalyzable
  #
  # Validator methods for choosing the right analyzer depending on the file
  # media type and available third-party analyzers.
  module ASVAnalyzable
    extend ActiveSupport::Concern

    DEFAULT_IMAGE_PROCESSOR = :mini_magick.freeze

    private

    # Retrieve the ASV metadata from the blob.
    # If the blob has not been analyzed by our gem yet, the gem will analyze the
    # attachable with the corresponding analyzer and set the metadata in the
    # blob.
    def metadata_for(blob, attachable, metadata_keys)
      return blob.active_storage_validations_metadata if blob_has_asv_metadata?(blob, metadata_keys)

      new_metadata = generate_metadata_for(attachable, metadata_keys)
      blob.merge_into_active_storage_validations_metadata(new_metadata)
    end

    def blob_has_asv_metadata?(blob, metadata_keys)
      return false unless blob.active_storage_validations_metadata.present?

      metadata_keys.all? { |key| blob.active_storage_validations_metadata.key?(key) }
    end

    def generate_metadata_for(attachable, metadata_keys)
      if metadata_keys == ActiveStorageValidations::ContentTypeValidator::METADATA_KEYS
        content_type_analyzer_for(attachable).content_type
      else
        metadata_analyzer_for(attachable).metadata
      end
    end

    def metadata_analyzer_for(attachable)
      return pdf_analyzer_for(attachable) if attachable_content_type(attachable) == "application/pdf"

      case attachable_media_type(attachable)
      when "image" then image_analyzer_for(attachable)
      when "video" then video_analyzer_for(attachable)
      when "audio" then audio_analyzer_for(attachable)
      else fallback_analyzer_for(attachable)
      end
    end

    def pdf_analyzer_for(attachable)
      ActiveStorageValidations::Analyzer::PdfAnalyzer.new(attachable)
    end

    def image_analyzer_for(attachable)
      case image_processor
      when :mini_magick
        ActiveStorageValidations::Analyzer::ImageAnalyzer::ImageMagick.new(attachable)
      when :vips
        ActiveStorageValidations::Analyzer::ImageAnalyzer::Vips.new(attachable)
      end
    end

    def image_processor
      # Rails returns nil for default image processor, because it is set in an after initialize callback
      # https://github.com/rails/rails/blob/main/activestorage/lib/active_storage/engine.rb
      ActiveStorage.variant_processor || DEFAULT_IMAGE_PROCESSOR
    end

    def video_analyzer_for(attachable)
      ActiveStorageValidations::Analyzer::VideoAnalyzer.new(attachable)
    end

    def audio_analyzer_for(attachable)
      ActiveStorageValidations::Analyzer::AudioAnalyzer.new(attachable)
    end

    def fallback_analyzer_for(attachable)
      ActiveStorageValidations::Analyzer::NullAnalyzer.new(attachable)
    end

    def content_type_analyzer_for(attachable)
      ActiveStorageValidations::Analyzer::ContentTypeAnalyzer.new(attachable)
    end
  end
end
