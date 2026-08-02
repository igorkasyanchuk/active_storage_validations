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
          # Best-effort: avoid unlinking the tempfile while a timed-out FFI load
          # may still be using the path.
          wait_for_vips_load_thread
          tempfile.close
        end
      end
    rescue ::Vips::Error => error
      logger.error "Skipping image analysis due to a Vips error: #{error.message}"
      {}
    end

    def media_from_path(path)
      instrument("vips") do |payload|
        load_vips_image(path, payload)
      end
    end

    def load_vips_image(path, payload)
      timeout = timeout_in_seconds
      return open_vips_image(path) if timeout.nil?

      result = nil
      @vips_load_thread = Thread.new { result = open_vips_image(path) }

      if @vips_load_thread.join(timeout)
        result
      else
        # libvips work may continue in the background until the C call returns.
        mark_timed_out!(payload, "vips")
        nil
      end
    end

    def wait_for_vips_load_thread
      return unless @vips_load_thread&.alive?

      @vips_load_thread.join(0.5)
    end

    # Returns nil for unsupported / empty files instead of raising.
    # Vips raises on unreadable input (e.g. 0-byte files) rather than returning
    # a falsy image — see https://github.com/janko/image_processing/issues/97
    def open_vips_image(path)
      ::Vips::Image.new_from_file(path, access: :sequential)
    rescue ::Vips::Error
      nil
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
