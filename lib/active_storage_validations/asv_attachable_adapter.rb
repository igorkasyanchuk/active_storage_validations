# frozen_string_literal: true

module ActiveStorageValidations
  # Wraps a Rails attachable so callers do not repeat the type-dispatch case tree.
  #
  # Must not be named +Attachable+: ActiveStorageValidations is included into
  # Active Record, so +include Attachable+ in an app model under this namespace
  # would resolve to this class instead of the app's concern.
  #
  # Supported representations: ActiveStorage::Blob, ActionDispatch::Http::UploadedFile,
  # Rack::Test::UploadedFile, Hash, File, Pathname, and a signed blob id (String).
  #
  # Every handler exposes the same three methods: +content_type+, +filename+
  # and +with_media_path+ (a filesystem path the analyzer commands can read).
  # +with_media_path(tempfile, max_bytes:)+ lets an analyzer that only inspects
  # the beginning of a file (libmagic) avoid downloading / copying all of it.
  class ASVAttachableAdapter
    def self.wrap(attachable, file_supported:)
      handler_class_for(attachable).new(attachable, file_supported: file_supported)
    end

    # Filename for error options. Unknown types return nil (never raise).
    # File / Pathname are always accepted here so a validation error can name
    # the file even on Rails versions that cannot attach them.
    def self.filename_for(file)
      case file
      when ActiveStorage::Attached, ActiveStorage::Attachment
        file.blob&.filename
      else
        return unless known?(file)

        wrap(file, file_supported: true).filename
      end
    end

    def self.known?(attachable)
      handler_class_for(attachable) != Unsupported
    end
    private_class_method :known?

    def self.handler_class_for(attachable)
      case attachable
      when ActiveStorage::Blob then Blob
      when ActionDispatch::Http::UploadedFile, Rack::Test::UploadedFile then Uploaded
      when String then SignedId
      when Hash then HashIo
      when File then FileLike
      when Pathname then Path
      else Unsupported
      end
    end
    private_class_method :handler_class_for

    class Base
      def initialize(attachable, file_supported:)
        @attachable = attachable
        @file_supported = file_supported
      end

      def content_type
        raise NotImplementedError
      end

      def filename
        raise NotImplementedError
      end

      def with_media_path(_tempfile, max_bytes: nil)
        raise NotImplementedError
      end

      private

      def raise_unsupported
        raise ArgumentError,
          "Could not find or build blob: expected attachable, " \
            "got #{@attachable.inspect}"
      end

      def copy_to_tempfile(tempfile, source, max_bytes: nil)
        if source.is_a?(ActiveStorage::Blob)
          download_blob(tempfile, source, max_bytes)
        else
          IO.copy_stream(source, tempfile, max_bytes)
          source.rewind
        end

        tempfile.flush
        tempfile.rewind
        yield tempfile.path
      end

      def download_blob(tempfile, blob, max_bytes)
        if max_bytes && blob.byte_size.to_i > max_bytes
          tempfile.write(blob.download_chunk(0...max_bytes))
        else
          blob.download { |chunk| tempfile.write(chunk) }
        end
      end

      def marcel_content_type
        Marcel::MimeType.for(name: filename.to_s)
      end
    end

    class Blob < Base
      def content_type
        @attachable.content_type
      end

      def filename
        @attachable.filename
      end

      def with_media_path(tempfile, max_bytes: nil, &block)
        copy_to_tempfile(tempfile, @attachable, max_bytes: max_bytes, &block)
      end
    end

    class SignedId < Blob
      def initialize(attachable, file_supported:)
        super(ActiveStorage::Blob.find_signed!(attachable), file_supported: file_supported)
      end
    end

    class Uploaded < Base
      def content_type
        @attachable.content_type
      end

      def filename
        @attachable.original_filename
      end

      def with_media_path(_tempfile, max_bytes: nil)
        yield @attachable.path
      end
    end

    class HashIo < Base
      def content_type
        @attachable[:content_type]
      end

      def filename
        @attachable[:filename]
      end

      # Rails only requires the io to respond to #read / #rewind / #size, so it
      # may be a StringIO or any IO-like wrapper (streaming download, Zip entry,
      # …) with no file behind it. Only path-backed IOs (File, Tempfile,
      # uploaded files) can be handed to the analyzers' commands as they are.
      def with_media_path(tempfile, max_bytes: nil, &block)
        io = @attachable[:io]
        if io.respond_to?(:to_path)
          File.open(io) { |file| yield file.path }
        else
          copy_to_tempfile(tempfile, io, max_bytes: max_bytes, &block)
        end
      end
    end

    class FileLike < Base
      def initialize(attachable, file_supported:)
        super
        raise_unsupported unless file_supported
      end

      def content_type
        marcel_content_type
      end

      def filename
        File.basename(@attachable)
      end

      def with_media_path(_tempfile, max_bytes: nil)
        yield @attachable.path
      end
    end

    class Path < FileLike
      def with_media_path(_tempfile, max_bytes: nil)
        yield @attachable.to_s
      end
    end

    class Unsupported < Base
      def initialize(attachable, file_supported:)
        super
        raise_unsupported
      end
    end
  end
end
