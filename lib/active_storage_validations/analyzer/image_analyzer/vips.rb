# frozen_string_literal: true

module ActiveStorageValidations
  # This analyzer relies on the third-party {ruby-vips}[https://github.com/libvips/ruby-vips] gem.
  # Ruby-vips requires the {libvips}[https://libvips.github.io/libvips/] system library.
  class Analyzer::ImageAnalyzer::Vips < Analyzer::ImageAnalyzer
    private

    def read_media
      Tempfile.create(binmode: true) do |tempfile|
        begin
          if media(tempfile)
            yield media(tempfile)
          else
            logger.info "Skipping image analysis because Vips doesn't support the file"
            {}
          end
        ensure
          tempfile.close
        end
      end
    rescue ::Vips::Error => error
      logger.error "Skipping image analysis due to a Vips error: #{error.message}"
      {}
    end

    def media_from_path(path)
      instrument("vips") do
        begin
          ::Vips::Image.new_from_file(path, access: :sequential)
        rescue ::Vips::Error
          # Vips throw errors rather than returning false when reading a not
          # supported attachable.
          # We stumbled upon this issue while reading 0 byte size attachable
          # https://github.com/janko/image_processing/issues/97
          nil
        end
      end
    end

    ROTATIONS = /Right-top|Left-bottom|Top-right|Bottom-left/
    def rotated_image?(image)
      ROTATIONS === image.get("exif-ifd0-Orientation")
    rescue ::Vips::Error
      false
    end

    def supported?
      require "vips"
      true
    rescue LoadError
      logger.info "Skipping image analysis because the ruby-vips gem isn't installed"
      false
    end
  end
end
