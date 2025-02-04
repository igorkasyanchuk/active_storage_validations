# frozen_string_literal: true

require_relative "shared/asv_attachable"
require_relative "shared/asv_loggable"

module ActiveStorageValidations
  # = Active Storage Validations \Analyzer
  #
  # This is an abstract base class for analyzers, which extract metadata from attachables.
  # See ActiveStorageValidations::Analyzer::VideoAnalyzer for an example of a concrete subclass.
  #
  # Heavily (not to say 100%) inspired by Rails own ActiveStorage::Analyzer
  class Analyzer
    include ASVAttachable
    include ASVLoggable

    attr_reader :attachable

    def initialize(attachable)
      @attachable = attachable
    end

    # Override this method in a concrete subclass. Have it return a String content type.
    def content_type
      raise NotImplementedError
    end

    # Override this method in a concrete subclass. Have it return a Hash of metadata.
    def metadata
      raise NotImplementedError
    end

    private

    # Override this method in a concrete subclass. Have it yield a media object.
    def read_media
      raise NotImplementedError
    end

    # rubocop:disable Metrics/MethodLength
    def media(tempfile)
      @media ||= case @attachable
      when ActiveStorage::Blob, String
        blob = @attachable.is_a?(String) ? ActiveStorage::Blob.find_signed!(@attachable) : @attachable
        media_from_tempfile_path(tempfile, blob)
      when Hash
        io = @attachable[:io]
        if io.is_a?(StringIO)
          media_from_tempfile_path(tempfile, io)
        else
          File.open(io) do |file|
            media_from_path(file.path)
        end
        end
      when ActionDispatch::Http::UploadedFile, Rack::Test::UploadedFile
        media_from_path(@attachable.path)
      when File
        supports_file_attachment? ? media_from_path(@attachable.path) : raise_rails_like_error(@attachable)
      when Pathname
        supports_pathname_attachment? ? media_from_path(@attachable.to_s) : raise_rails_like_error(@attachable)
      else
        raise_rails_like_error(@attachable)
      end
    end

    def media_from_tempfile_path(tempfile, file_representation)
      if file_representation.is_a?(ActiveStorage::Blob)
        file_representation.download { |chunk| tempfile.write(chunk) }
      else
        IO.copy_stream(file_representation, tempfile)
        file_representation.rewind
      end

      tempfile.flush
      tempfile.rewind
      media_from_path(tempfile.path)
    end

    # Override this method in a concrete subclass. Have it return a media object.
    def media_from_path(path)
      raise NotImplementedError
    end

    def instrument(analyzer, &block)
      ActiveSupport::Notifications.instrument("analyze.active_storage_validations", analyzer: analyzer, &block)
    end
  end
end
