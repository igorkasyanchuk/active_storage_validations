module ActiveStorageValidations
  class Metadata
    attr_reader :file

    def initialize(file)
      @file = file
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

    def read_image
      is_string = file.is_a?(String)
      if is_string || file.is_a?(ActiveStorage::Blob)
        if is_string
          # If Rails 5.2 or 6.0, use `find_signed`
          if Rails::VERSION::MAJOR < 6 || (Rails::VERSION::MAJOR == 6 && Rails::VERSION::MINOR == 0)
            blob = ActiveStorage::Blob.find_signed(file)
          # If Rails 6.1 or higher, use `find_signed!`
          elsif Rails::VERSION::MAJOR > 6 || (Rails::VERSION::MAJOR == 6 && Rails::VERSION::MINOR >= 1)
            blob = ActiveStorage::Blob.find_signed!(file)
          end
        else
          blob = file
        end

        tempfile = Tempfile.new(["ActiveStorage-#{blob.id}-", blob.filename.extension_with_delimiter])
        tempfile.binmode

        blob.download do |chunk|
          tempfile.write(chunk)
        end

        tempfile.flush
        tempfile.rewind

        image = MiniMagick::Image.new(tempfile.path)
      else
        image = MiniMagick::Image.new(read_file_path)
      end

      if image.valid?
        yield image
      else
        logger.info "Skipping image analysis because ImageMagick doesn't support the file"
        {}
      end
    rescue LoadError
      logger.info "Skipping image analysis because the mini_magick gem isn't installed"
      {}
    rescue MiniMagick::Error => error
      logger.error "Skipping image analysis due to an ImageMagick error: #{error.message}"
      {}
    ensure
      image = nil
    end

    def rotated_image?(image)
      %w[ RightTop LeftBottom ].include?(image["%[orientation]"])
    end

    def read_file_path
      case file
      when ActionDispatch::Http::UploadedFile, Rack::Test::UploadedFile
        file.path
      when Hash
        File.open(file.fetch(:io)).path
      else
        raise "Something wrong with params."
      end
    end

    def logger
      Rails.logger
    end

  end
end
