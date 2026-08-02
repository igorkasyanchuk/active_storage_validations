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
      if content_type_metadata_keys?(metadata_keys)
        return content_type_metadata_for(blob, attachable)
      end

      return blob.active_storage_validations_metadata if blob_has_asv_metadata?(blob, metadata_keys)

      new_metadata = generate_metadata_for(attachable, metadata_keys) || {}
      blob.merge_into_active_storage_validations_metadata(new_metadata)
      blob.save!

      blob.active_storage_validations_metadata
    end

    def content_type_metadata_keys?(metadata_keys)
      metadata_keys == ActiveStorageValidations::ContentTypeValidator::METADATA_KEYS
    end

    # Same cache semantics as +metadata_for+, plus backend matching.
    # Legacy blobs that only have +asv_content_type+ (no backend key) are treated
    # as +:file+ — so existing file-backend analyses keep hitting the cache and
    # are not re-analyzed / rewritten.
    def content_type_metadata_for(blob, attachable)
      backend = spoofing_protection_backend
      cached = blob.active_storage_validations_metadata
      return cached if content_type_cache_hit?(cached, backend)

      metadata_keys = ActiveStorageValidations::ContentTypeValidator::METADATA_KEYS
      new_metadata = generate_metadata_for(attachable, metadata_keys)
      return failed_content_type_metadata(backend) if content_type_analysis_failed?(new_metadata)

      blob.merge_into_active_storage_validations_metadata(new_metadata)
      blob.save!

      blob.active_storage_validations_metadata
    end

    def content_type_analysis_failed?(new_metadata)
      new_metadata.blank? || new_metadata[:content_type].blank?
    end

    # Do not return / persist another backend's cached type after a failed sniff
    # (timeout, unsupported file, invalid Magika JSON, …). Fail closed for this
    # request; leave blob metadata unchanged so a later attempt can retry.
    def failed_content_type_metadata(backend)
      { content_type: nil, content_type_backend: backend.to_s }
    end

    def content_type_cache_hit?(cached, backend)
      return false unless cached.present? && cached[:content_type].present?

      # Missing / blank backend => legacy file analysis (pre-Magika support).
      # Those blobs keep hitting the cache for +:file+ and are not rewritten.
      stored_backend = (cached[:content_type_backend].presence || "file").to_s
      stored_backend == backend.to_s
    end

    def blob_has_asv_metadata?(blob, metadata_keys)
      return false unless blob.active_storage_validations_metadata.present?

      metadata_keys.all? { |key| blob.active_storage_validations_metadata.key?(key) }
    end

    def generate_metadata_for(attachable, metadata_keys)
      if content_type_metadata_keys?(metadata_keys)
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
      ActiveStorageValidations::Analyzer::PdfAnalyzer.new(attachable, **analyzer_timeout_options)
    end

    def image_analyzer_for(attachable)
      case image_processor
      when :mini_magick
        ActiveStorageValidations::Analyzer::ImageAnalyzer::ImageMagick.new(attachable, **analyzer_timeout_options)
      when :vips
        ActiveStorageValidations::Analyzer::ImageAnalyzer::Vips.new(attachable, **analyzer_timeout_options)
      end
    end

    def image_processor
      # Rails returns nil for default image processor, because it is set in an after initialize callback
      # https://github.com/rails/rails/blob/main/activestorage/lib/active_storage/engine.rb
      ActiveStorage.variant_processor || DEFAULT_IMAGE_PROCESSOR
    end

    def video_analyzer_for(attachable)
      ActiveStorageValidations::Analyzer::VideoAnalyzer.new(attachable, **analyzer_timeout_options)
    end

    def audio_analyzer_for(attachable)
      ActiveStorageValidations::Analyzer::AudioAnalyzer.new(attachable, **analyzer_timeout_options)
    end

    def fallback_analyzer_for(attachable)
      ActiveStorageValidations::Analyzer::NullAnalyzer.new(attachable, **analyzer_timeout_options)
    end

    def content_type_analyzer_for(attachable)
      case spoofing_protection_backend
      when :magika
        ActiveStorageValidations::Analyzer::ContentTypeAnalyzer::Magika.new(attachable, **analyzer_timeout_options)
      else
        ActiveStorageValidations::Analyzer::ContentTypeAnalyzer::File.new(attachable, **analyzer_timeout_options)
      end
    end

    # Passes raw validator +timeout:+ through to analyzers. Kept out of
    # AVAILABLE_CHECKS so ASVOptionable does not flatten it as a comparison bound.
    def analyzer_timeout_options
      options.key?(:timeout) ? { timeout: options[:timeout] } : {}
    end
  end
end
