module ActiveStorageValidations
  class Metadata
    attr_reader :file

    def initialize(file)
      require_image_processor
      @file = file
    end

    def image_processor
      Rails.application.config.active_storage.variant_processor
    end
    
    def exception_class
      if image_processor == :vips && defined?(Vips)
        Vips::Error
      elsif defined?(MiniMagick)
        MiniMagick::Error
      end
    end

    def require_image_processor
      if image_processor == :vips
        require 'vips' unless defined?(Vips)
      else
        require 'mini_magick' unless defined?(MiniMagick)
      end
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
        blob =
          if is_string
            if Rails.gem_version < Gem::Version.new('6.1.0')
              ActiveStorage::Blob.find_signed(file)
            else
              ActiveStorage::Blob.find_signed!(file)
            end
          else
            file
          end

        tempfile = Tempfile.new(["ActiveStorage-#{blob.id}-", blob.filename.extension_with_delimiter])
        tempfile.binmode

        blob.download do |chunk|
          tempfile.write(chunk)
        end

        tempfile.flush
        tempfile.rewind

        image = if image_processor == :vips && defined?(Vips) && Vips::get_suffixes.include?(File.extname(tempfile.path).downcase)
                  Vips::Image.new_from_file(tempfile.path)
                elsif defined?(MiniMagick)
                  MiniMagick::Image.new(tempfile.path)
                end
      else
        image = if image_processor == :vips && defined?(Vips) && Vips::get_suffixes.include?(File.extname(read_file_path).downcase)
                  Vips::Image.new_from_file(read_file_path)
                elsif defined?(MiniMagick)
                  MiniMagick::Image.new(read_file_path)
                end
      end

      if image && valid_image?(image)
        yield image
      else
        logger.info "Skipping image analysis because ImageMagick or Vips doesn't support the file"
        {}
      end
    rescue LoadError, NameError
      logger.info "Skipping image analysis because the mini_magick or ruby-vips gem isn't installed"
      {}
    rescue exception_class => error
      logger.error "Skipping image analysis due to an #{exception_class.name.split('::').map(&:downcase).join(' ').capitalize} error: #{error.message}"
      {}
    ensure
      image = nil
    end

    def valid_image?(image)
      image_processor == :vips && image.is_a?(Vips::Image) ? image.avg : image.valid?
    rescue exception_class
      false
    end

    def rotated_image?(image)
      if image_processor == :vips && image.is_a?(Vips::Image)
        image.get('exif-ifd0-Orientation').include?('Right-top') ||
          image.get('exif-ifd0-Orientation').include?('Left-bottom')
      else
        %w[ RightTop LeftBottom ].include?(image["%[orientation]"])
      end
    rescue exception_class # field "exif-ifd0-Orientation" not found
      false
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
