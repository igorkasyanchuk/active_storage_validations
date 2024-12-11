# frozen_string_literal: true

module ActiveStorageValidations
  # This analyzer relies on the third-party {MiniMagick}[https://github.com/minimagick/minimagick] gem.
  # MiniMagick requires the {ImageMagick}[http://www.imagemagick.org] system library.
  # This is the default Rails image analyzer.
  class Analyzer::ImageAnalyzer::ImageMagick < Analyzer::ImageAnalyzer

    private

    def read_image
      begin
        require "mini_magick" unless defined?(MiniMagick)
      rescue LoadError
        logger.info "Skipping image analysis because the mini_magick gem isn't installed"
        return {}
      end

      Tempfile.create(binmode: true) do |tempfile|
        begin
          if image(tempfile).valid?
            yield image(tempfile)
          else
            logger.info "Skipping image analysis because ImageMagick doesn't support the file"
            {}
          end
        ensure
          tempfile.close
        end
      end
    rescue MiniMagick::Error => error
      logger.error "Skipping image analysis due to an ImageMagick error: #{error.message}"
      {}
    end

    def image_from_path(path)
      instrument("mini_magick") do
        MiniMagick::Image.new(path)
      end
    end

    def rotated_image?(image)
      %w[ RightTop LeftBottom TopRight BottomLeft ].include?(image["%[orientation]"])
    end
  end
end
