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
    # What browsers and clients send when they do not know the type.
    GENERIC_CONTENT_TYPE = "application/octet-stream"
    # Set on the validation error reported for a file whose media analysis
    # produced nothing, see #share_failed_analysis.
    FailedAnalysis = Struct.new(:blob, :timeout_options)
    FAILED_ANALYSIS = :@active_storage_validations_failed_analysis

    private

    # #metadata_for, unless another validator of this validation already ran
    # the same analysis for nothing (#share_failed_analysis): the blob's cached
    # metadata is then returned as it is, which is what #metadata_for returns
    # on a cache hit and after a failed analysis.
    def metadata_for_validation(record, blob, attachable, metadata_keys)
      return media_metadata(blob) if failed_analysis_shared?(record, blob)

      metadata_for(blob, attachable, metadata_keys)
    end

    # An analysis that produced nothing (missing CLI, timed out command,
    # unreadable file) is not cached on the blob, so that a later validation
    # retries it. Every metadata validator of the attribute therefore ran it
    # again within the same validation: dimension + duration + with_audio +
    # processable_file on a file that hangs ffprobe held the request for four
    # timeouts, and downloaded a blob four times.
    #
    # The failure is remembered on the error this validator just added for the
    # file (+errors_count+ is the number of errors before it ran), so it lasts
    # exactly as long as that error: `valid?` clears the errors, and the next
    # validation analyzes the file again. A validator that adds no error for
    # an unanalyzable file shares nothing, and the next one analyzes it.
    def share_failed_analysis(record, blob, metadata_keys, errors_count)
      # The error first: a valid file, the usual case, costs nothing more.
      error = record.errors.objects[errors_count]
      return if error.nil? || blob_has_asv_metadata?(blob, metadata_keys)

      error.instance_variable_set(FAILED_ANALYSIS, FailedAnalysis.new(blob, analyzer_timeout_options))
    end

    # Only shared between validators that analyze with the same timeout: a
    # validator with a longer `timeout:` may succeed where another one gave up.
    def failed_analysis_shared?(record, blob)
      return false if record.errors.empty?

      timeout_options = analyzer_timeout_options
      record.errors.objects.any? do |error|
        failed_analysis = error.instance_variable_get(FAILED_ANALYSIS)
        failed_analysis && failed_analysis.blob.equal?(blob) && failed_analysis.timeout_options == timeout_options
      end
    end

    # Retrieve the ASV metadata from the blob.
    # If the blob has not been analyzed by our gem yet, the gem will analyze the
    # attachable with the corresponding analyzer and set the metadata in the
    # blob.
    def metadata_for(blob, attachable, metadata_keys)
      if content_type_metadata_keys?(metadata_keys)
        return content_type_metadata_for(blob, attachable)
      end

      return media_metadata(blob) if blob_has_asv_metadata?(blob, metadata_keys)

      new_metadata = generate_metadata_for(attachable, metadata_keys, blob) || {}
      blob.merge_into_active_storage_validations_metadata(memoize_unavailable_keys(new_metadata, metadata_keys))
      persist_asv_metadata(blob)

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
      persist_asv_metadata(blob)

      blob.active_storage_validations_metadata
    end

    # A bare +valid?+ on a new record must not INSERT an +active_storage_blobs+
    # row (no file on the service, orphaned if the record is never saved).
    # In-memory +asv_*+ on the unsaved blob is persisted by Rails when the
    # record is saved. Already-persisted blobs (re-validation, attach after
    # save, pre-v2 blobs) still need +save!+ so the cache survives +reload+.
    #
    # In a reading role (automatic role switching on GET requests,
    # +connected_to(role: :reading)+) the blob cannot be written: keep the
    # analysis in memory for this validation instead of raising from +valid?+.
    def persist_asv_metadata(blob)
      blob.save! if blob.persisted?
    rescue ActiveRecord::ReadOnlyError, ActiveRecord::ReadOnlyRecord
      nil
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

    def generate_metadata_for(attachable, metadata_keys, blob = nil)
      if content_type_metadata_keys?(metadata_keys)
        content_type_analyzer_for(attachable).content_type
      else
        metadata_analyzer_for(attachable, blob).metadata
      end
    end

    def metadata_analyzer_for(attachable, blob = nil)
      content_type = analyzable_content_type(attachable, blob)
      return pdf_analyzer_for(attachable) if content_type == "application/pdf"

      case content_type.to_s.split("/").first
      when "image" then image_analyzer_for(attachable)
      when "video" then video_analyzer_for(attachable)
      when "audio" then audio_analyzer_for(attachable)
      else fallback_analyzer_for(attachable)
      end
    end

    # Pick the analyzer from the declared type (downcased, parameters removed),
    # then from the type Rails identified for the blob (its magic bytes, unless
    # attached with `identify: false`), then from the filename. Blank and
    # generic types are skipped: a PNG uploaded as application/octet-stream,
    # IMAGE/PNG or "" used to get the null analyzer (file_not_processable).
    #
    # The declared type stays first on purpose: routing on the identified type
    # would analyze a video or PDF uploaded as image/png with the video / PDF
    # analyzer, so image-only validators (dimension, aspect_ratio,
    # processable_file) would accept it.
    def analyzable_content_type(attachable, blob)
      [ full_attachable_content_type(attachable), blob&.content_type ].each do |type|
        type = content_type_without_parameters(type.to_s)
        return type if type.present? && type != GENERIC_CONTENT_TYPE
      end

      marcel_content_type_from_filename(attachable)
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
      else
        # Unknown processors must not return nil — `.metadata` would raise from
        # valid? instead of failing closed.
        fallback_analyzer_for(attachable)
      end
    end

    def image_processor
      # Rails returns nil for default image processor, because it is set in an after initialize callback
      # https://github.com/rails/rails/blob/main/activestorage/lib/active_storage/engine.rb
      # `:disabled` (Rails 8.1) only turns variants off, and Rails tells apps
      # without the image_processing gem to set it: their images are analyzed
      # with the default processor, as when none is set. An unknown processor
      # fails closed (#image_analyzer_for).
      processor = ActiveStorage.variant_processor
      processor = DEFAULT_IMAGE_PROCESSOR if processor.nil? || processor == :disabled
      processor.is_a?(Class) ? image_processor_for_transformer(processor) : processor
    end

    # Rails 8.2+ also accepts a transformer class
    # (`config.active_storage.variant_processor = MyTransformer`). It names the
    # image library only when it extends Rails' ImageMagick transformer; any
    # other class is analyzed with libvips, Rails' default transformer, instead
    # of failing every image. Ancestors are compared by name: referencing the
    # constants would autoload them, and they require the image_processing gem.
    def image_processor_for_transformer(transformer)
      ancestor_names = transformer.ancestors.map(&:name)

      ancestor_names.include?("ActiveStorage::Transformers::ImageMagick") ? :mini_magick : :vips
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
