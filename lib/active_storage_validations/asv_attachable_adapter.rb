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

      def read(max_byte_size: nil)
        raise NotImplementedError
      end

      def rewind
      end

      def with_media_path(_tempfile)
        raise NotImplementedError
      end

      private

      def raise_unsupported
        raise ArgumentError,
          "Could not find or build blob: expected attachable, " \
            "got #{@attachable.inspect}"
      end

      def read_from(io, max_byte_size)
        max_byte_size ? io.read(max_byte_size) : io.read
      end

      def copy_to_tempfile(tempfile, source)
        if source.is_a?(ActiveStorage::Blob)
          source.download { |chunk| tempfile.write(chunk) }
        else
          IO.copy_stream(source, tempfile)
          source.rewind
        end

        tempfile.flush
        tempfile.rewind
        yield tempfile.path
      end

      # Hand +path+ to the analyzer commands only when it is a regular file
      # holding +io+'s content. An unlinked Tempfile, an anonymous one (its
      # #to_path is the tmp directory) or an IO with no file behind it (a
      # Rack::Test::UploadedFile built on a StringIO) is copied instead.
      #
      # The path is made absolute so a relative one (`-image.png`, `clip:1.mp4`)
      # is never read as a command-line option or an ffmpeg protocol.
      # File.absolute_path, unlike File.expand_path, leaves a leading `~` alone
      # (`~$lock.png`, an Office lock file, is not a home directory).
      def with_path_or_copy(tempfile, path, io, &block)
        if regular_file_of?(path, io)
          yield File.absolute_path(path)
        else
          copy_to_tempfile(tempfile, io, &block)
        end
      end

      # A closed IO (`File.open(path) { |f| record.avatar.attach(io: f, …) }`)
      # can neither be compared nor copied: its path is all there is left.
      def regular_file_of?(path, io)
        return false unless path.present? && File.file?(path)
        return true if io.respond_to?(:closed?) && io.closed?

        File.identical?(io, path)
      rescue SystemCallError, TypeError, IOError
        false
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

      def read(max_byte_size: nil)
        max_byte_size ? @attachable.download_chunk(0...max_byte_size) : @attachable.download
      end

      def with_media_path(tempfile, &block)
        copy_to_tempfile(tempfile, @attachable, &block)
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

      def read(max_byte_size: nil)
        read_from(@attachable, max_byte_size)
      end

      def rewind
        @attachable.rewind
      end

      def with_media_path(tempfile, &block)
        io = @attachable.tempfile
        path = io.path if io.respond_to?(:path)
        with_path_or_copy(tempfile, path, io, &block)
      end
    end

    class HashIo < Base
      def content_type
        @attachable[:content_type]
      end

      def filename
        @attachable[:filename]
      end

      def read(max_byte_size: nil)
        read_from(@attachable[:io], max_byte_size)
      end

      def rewind
        @attachable[:io].rewind
      end

      # Rails only requires the io to respond to #read / #rewind / #size, so it
      # may be a StringIO or any IO-like wrapper (streaming download, Zip entry,
      # …) with no file behind it. Only path-backed IOs (File, Tempfile,
      # uploaded files) can be handed to the analyzers' commands as they are.
      def with_media_path(tempfile, &block)
        io = @attachable[:io]
        path = io.to_path if io.respond_to?(:to_path)
        with_path_or_copy(tempfile, path, io, &block)
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

      def read(max_byte_size: nil)
        read_from(@attachable, max_byte_size)
      end

      def rewind
        @attachable.rewind
      end

      def with_media_path(tempfile, &block)
        with_path_or_copy(tempfile, @attachable.path, @attachable, &block)
      end
    end

    # Nothing to copy from: a missing file is left to the analyzer commands,
    # which fail closed.
    class Path < FileLike
      def rewind
        File.open(@attachable) { |file| file.rewind }
      end

      def with_media_path(_tempfile)
        yield File.absolute_path(@attachable.to_s)
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
