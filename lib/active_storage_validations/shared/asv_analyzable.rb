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

    def metadata_for(attachable)
      analyzer_for(attachable).metadata
    end

    def analyzer_for(attachable)
      case attachable_media_type(attachable)
      when "image" then image_analyzer_for(attachable)
      else fallback_analyzer_for(attachable)
      end
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

    def fallback_analyzer_for(attachable)
      ActiveStorageValidations::Analyzer::NullAnalyzer.new(attachable)
    end
  end
end
