# frozen_string_literal: true

module ActiveStorageValidations
  # = Active Storage Image \Analyzer
  #
  # This is an abstract base class for image analyzers, which extract width and height from an image attachable.
  #
  # If the image contains EXIF data indicating its angle is 90 or 270 degrees, its width and height are swapped for convenience.
  #
  # Example:
  #
  #   ActiveStorage::Analyzer::ImageAnalyzer::ImageMagick.new(attachable).metadata
  #   # => { width: 4104, height: 2736 }
  class Analyzer::ImageAnalyzer < Analyzer
    @@supported_analyzers = {}

    def metadata
      return {} unless analyzer_supported?

      read_image do |image|
        if rotated_image?(image)
          { width: image.height, height: image.width }
        else
          { width: image.width, height: image.height }
        end
      end
    end

    private

    def image(tempfile)
      case @attachable
      when ActiveStorage::Blob, String
        blob = @attachable.is_a?(String) ? ActiveStorage::Blob.find_signed!(@attachable) : @attachable
        image_from_tempfile_path(tempfile, blob)
      when Hash
        io = @attachable[:io]
        if io.is_a?(StringIO)
          image_from_tempfile_path(tempfile, io)
        else
          File.open(io) do |file|
            image_from_path(file.path)
          end
        end
      when ActionDispatch::Http::UploadedFile, Rack::Test::UploadedFile
        image_from_path(@attachable.path)
      when File
        supports_file_attachment? ? image_from_path(@attachable.path) : raise_rails_like_error(@attachable)
      when Pathname
        supports_pathname_attachment? ? image_from_path(@attachable.to_s) : raise_rails_like_error(@attachable)
      else
        raise_rails_like_error(@attachable)
      end
    end

    def image_from_tempfile_path(tempfile, file_representation)
      if file_representation.is_a?(ActiveStorage::Blob)
        file_representation.download { |chunk| tempfile.write(chunk) }
      else
        IO.copy_stream(file_representation, tempfile)
        file_representation.rewind
      end

      tempfile.flush
      tempfile.rewind
      image_from_path(tempfile.path)
    end

    def analyzer_supported?
      if @@supported_analyzers.key?(self)
        @@supported_analyzers.fetch(self)
      else
        @@supported_analyzers[self] = supported?
      end
    end

    def read_image
      raise NotImplementedError
    end

    def image_from_path(path)
      raise NotImplementedError
    end

    def rotated_image?(image)
      raise NotImplementedError
    end

    def supported?
      raise NotImplementedError
    end
  end
end
