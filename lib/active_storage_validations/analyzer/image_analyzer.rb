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
    def self.accept?(attachable)
      image?(attachable)
    end

    def metadata
      read_image do |image|
        if rotated_image?(image)
          { width: image.height, height: image.width }
        else
          { width: image.width, height: image.height }
        end
      end
    end

    private

    def image
      case @attachable
      when ActiveStorage::Blob, String
        blob = @attachable.is_a?(String) ? ActiveStorage::Blob.find_signed!(@attachable) : @attachable
        tempfile = tempfile_from_blob(blob)

        image_from_path(tempfile.path)
      when Hash
        io = @attachable[:io]
        file = io.is_a?(StringIO) ? tempfile_from_io(io) : File.open(io)

        image_from_path(file.path)
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

    def tempfile_from_blob(blob)
      tempfile = Tempfile.new(["ActiveStorage-#{blob.id}-", blob.filename.extension_with_delimiter], binmode: true)

      blob.download { |chunk| tempfile.write(chunk) }

      tempfile.flush
      tempfile.rewind
      tempfile
    end

    def tempfile_from_io(io)
      tempfile = Tempfile.new([File.basename(@attachable[:filename], '.*'), File.extname(@attachable[:filename])], binmode: true)

      IO.copy_stream(io, tempfile)
      io.rewind

      tempfile.flush
      tempfile.rewind
      tempfile
    end

    def image_from_path(path)
      raise NotImplementedError
    end

    def rotated_image?(image)
      raise NotImplementedError
    end
  end
end
