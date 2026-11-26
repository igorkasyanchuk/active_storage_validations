# frozen_string_literal: true

module ActiveStorageValidations
  # This analyzer relies on the third-party {ruby-vips}[https://github.com/libvips/ruby-vips] gem.
  # Ruby-vips requires the {libvips}[https://libvips.github.io/libvips/] system library.
  class Analyzer::ImageAnalyzer::Vips < Analyzer::ImageAnalyzer
    private

    def read_media
      create_media_tempfile do |tempfile|
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
      if self.class.skips_untrusted_loaders? && self.class.untrusted_loader?(path)
        logger.info "Skipping image analysis because its libvips loader is untrusted (unfuzzed)"
        return nil
      end

      ::Vips::Image.new_from_file(path, access: :sequential)
    rescue ::Vips::Error
      nil
    end

    # libvips' VipsOperationFlags values ruby-vips does not export.
    OPERATION_UNTRUSTED = 16
    OPERATION_BLOCKED = 32
    # Untrusted and built into every libvips 8.13+, so Vips.block_untrusted
    # always blocks them (several, in case a build leaves one out).
    UNTRUSTED_PROBE_OPERATIONS = %w[csvload rawload vipsload].freeze

    class << self
      # libvips flags some loaders (SVG, BMP, JPEG 2000, Netpbm, …) as unfuzzed:
      # only safe on trusted content. Rails 7.2.3.2+ / 8.0.5.1+ / 8.1.3.1+ and
      # image_processing 2.0+ call Vips.block_untrusted(true); older Rails do
      # not, and validation analyzes the raw upload before anything else does.
      # The gem then skips those loaders itself, file by file, without changing
      # the app's global setting. Once blocking is on, libvips enforces it, and
      # a loader the app re-enabled (`Vips.block(…, false)`) is used.
      def skips_untrusted_loaders?
        untrusted_flags_supported? && !untrusted_operations_blocked?
      end

      def untrusted_operations_blocked?
        UNTRUSTED_PROBE_OPERATIONS.any? { |nickname| operation_flags(nickname).anybits?(OPERATION_BLOCKED) }
      end

      def untrusted_loader?(path)
        loader = ::Vips.vips_foreign_find_load(path.to_s)
        return false unless loader

        operation_flags(::Vips.nickname_find(::GObject.g_type_from_name(loader))).anybits?(OPERATION_UNTRUSTED)
      end

      private

      def untrusted_flags_supported?
        ::Vips.respond_to?(:block_untrusted) && ::Vips.at_least_libvips?(8, 13)
      end

      def operation_flags(nickname)
        ::Vips.vips_operation_get_flags(::Vips::Operation.new(nickname))
      rescue ::Vips::Error, FFI::NotFoundError, TypeError, ArgumentError
        0
      end
    end

    # EXIF orientations 5 to 8 (Left-top, Right-top, Right-bottom, Left-bottom)
    # turn the image a quarter, 2 and 4 only mirror it. libvips sets
    # "orientation" for every format, "exif-ifd0-Orientation" is JPEG / WebP only
    # (a TIFF Orientation tag is not EXIF).
    QUARTER_TURN_ORIENTATIONS = 5..8
    def rotated_image?(image)
      QUARTER_TURN_ORIENTATIONS.cover?(image.get("orientation").to_i)
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
