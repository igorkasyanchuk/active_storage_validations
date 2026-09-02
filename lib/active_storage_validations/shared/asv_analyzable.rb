# frozen_string_literal: true

module ActiveStorageValidations
  # ActiveStorageValidations::ASVAnalyzable
  #
  # Validator methods for choosing the right analyzer depending on the file
  # media type and available third-party analyzers.
  module ASVAnalyzable
    extend ActiveSupport::Concern

    DEFAULT_IMAGE_PROCESSOR = :mini_magick
    # Keys written by the content-type sniffers. They record what the file
    # claims to be, not whether an analyzer could decode it, so they must never
    # count as evidence that a media analysis happened.
    CONTENT_TYPE_METADATA_KEYS = %i[content_type content_type_backend].freeze

    private

    # Retrieve the ASV metadata from the blob.
    # If the blob has not been analyzed by our gem yet, the gem will analyze the
    # attachable with the corresponding analyzer and set the metadata in the
    # blob.
    def metadata_for(blob, attachable, metadata_keys)
      if content_type_metadata_keys?(metadata_keys)
        return content_type_metadata_for(blob, attachable)
      end

      return media_metadata(blob) if blob_has_asv_metadata?(blob, metadata_keys)

      new_metadata = generate_metadata_for(attachable, metadata_keys) || {}
      blob.merge_into_active_storage_validations_metadata(memoize_unavailable_keys(new_metadata, metadata_keys))
      blob.save!

      media_metadata(blob)
    end

    # The metadata produced by the media analyzers, i.e. everything the blob
    # carries except the content-type sniffer keys. Validators that ask for an
    # empty METADATA_KEYS (ProcessableFileValidator) treat a non-empty result as
    # proof that an analyzer decoded the file, so a cached +asv_content_type+
    # left behind by spoofing_protection must not leak into it.
    def media_metadata(blob)
      blob.active_storage_validations_metadata.except(*CONTENT_TYPE_METADATA_KEYS)
    end

    # Analyzers only return the keys they could extract, so a requested key the
    # analyzer cannot produce for this file (e.g. :duration for an image) would
    # never be cached and the expensive analysis would run again on every
    # validation. Store those keys as blank to memoize the miss: the validator
    # still sees no usable value and adds its usual error, but only analyzes once.
    #
    # An entirely empty result means no analysis happened at all — missing CLI,
    # timed out command, unreadable file — so it is left unmemoized and retried
    # on the next validation.
    #
    # Teaching an existing analyzer a new metadata key therefore requires
    # clearing the misses memoized by previous versions of the gem, see
    # ASVBlobMetadatable#remove_active_storage_validations_metadata!.
    def memoize_unavailable_keys(new_metadata, metadata_keys)
      return new_metadata if new_metadata.blank?

      unavailable_keys = metadata_keys.reject { |key| new_metadata.key?(key) }
      new_metadata.merge(unavailable_keys.index_with(nil))
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
      cached = media_metadata(blob)
      return false unless cached.present?

      metadata_keys.all? { |key| cached.key?(key) }
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
