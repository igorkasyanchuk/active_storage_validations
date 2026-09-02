# frozen_string_literal: true

module ActiveStorageValidations
  # = ActiveStorageValidations Image \Analyzer
  #
  # This is an abstract base class for image analyzers, which extract width and height from an image attachable.
  #
  # If the image contains EXIF data indicating its angle is 90 or 270 degrees, its width and height are swapped for convenience.
  #
  # Example:
  #
  #   ActiveStorageValidations::Analyzer::ImageAnalyzer::ImageMagick.new(attachable).metadata
  #   # => { width: 4104, height: 2736 }
  class Analyzer::ImageAnalyzer < Analyzer
    class << self
      def reset_supported_analyzers_cache!
        @supported_analyzers = {}
      end

      def supported_analyzers
        @supported_analyzers ||= {}
      end
    end

    def metadata
      return {} unless analyzer_supported?

      read_media do |media|
        if rotated_image?(media)
          { width: media.height, height: media.width }
        else
          { width: media.width, height: media.height }
        end
      end
    end

    private

    # Cache by class, not instance: a new analyzer is built per attachable, so
    # an instance-keyed hash never hits and retains every attachable for the
    # process lifetime.
    def analyzer_supported?
      cache = Analyzer::ImageAnalyzer.supported_analyzers
      return cache[self.class] if cache.key?(self.class)

      cache[self.class] = supported?
    end

    # Override this method in a concrete subclass. Have it return true if the image is rotated.
    def rotated_image?(media)
      raise NotImplementedError
    end

    # Override this method in a concrete subclass. Have it return true if the analyzer is supported.
    def supported?
      raise NotImplementedError
    end
  end
end
