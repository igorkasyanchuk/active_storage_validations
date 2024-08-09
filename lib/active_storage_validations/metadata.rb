module ActiveStorageValidations
  class Metadata
    class InvalidImageError < StandardError; end

    attr_reader :file

    DEFAULT_IMAGE_PROCESSOR = :mini_magick.freeze

    def initialize(file)
      require_image_processor
      @file = file
    end

    def valid?
      read_image
      true
    rescue InvalidImageError
      false
    end

    def metadata
      read_image do |image|
        if rotated_image?(image)
          { width: image.height, height: image.width }
        else
          { width: image.width, height: image.height }
        end
      end
    rescue InvalidImageError
      logger.info "Skipping image analysis because ImageMagick or Vips doesn't support the file"
      {}
    end

    private

    def image_processor
      # Rails returns nil for default image processor, because it is set in an after initialize callback
      # https://github.com/rails/rails/blob/89d8569abe2564c8187debf32dd3b4e33d6ad983/activestorage/lib/active_storage/engine.rb
      Rails.application.config.active_storage.variant_processor || DEFAULT_IMAGE_PROCESSOR
    end

    def require_image_processor
      case image_processor
      when :vips then require 'vips' unless defined?(Vips)
      when :mini_magick then require 'mini_magick' unless defined?(MiniMagick)
      end
    end

    def exception_class
      case image_processor
      when :vips then Vips::Error
      when :mini_magick then MiniMagick::Error
      end
    end

    def vips_image_processor?
      image_processor == :vips
    end

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

        image = new_image_from_path(tempfile.path)
      else
        file_path = read_file_path
        image = new_image_from_path(file_path)
      end


      raise InvalidImageError unless valid_image?(image)
      yield image if block_given?
    rescue LoadError, NameError
      logger.info "Skipping image analysis because the mini_magick or ruby-vips gem isn't installed"
      {}
    rescue exception_class => error
      logger.error "Skipping image analysis due to an #{exception_class.name.split('::').map(&:downcase).join(' ').capitalize} error: #{error.message}"
      {}
    ensure
      image = nil
    end

    def new_image_from_path(path)
      if vips_image_processor? && (supported_vips_suffix?(path) || vips_version_below_8_8? || open_uri_tempfile?(path))
        begin
          Vips::Image.new_from_file(path)
        rescue exception_class
          # We handle cases where an error is raised when reading the file
          # because Vips can throw errors rather than returning false
          # We stumble upon this issue while reading 0 byte size file
          # https://github.com/janko/image_processing/issues/97
          false
        end
      elsif defined?(MiniMagick)
        MiniMagick::Image.new(path)
      end
    end

    def supported_vips_suffix?(path)
      Vips::get_suffixes.include?(File.extname(path).downcase)
    end

    def vips_version_below_8_8?
      # FYI, Vips 8.8 was released in 2019
      # https://github.com/libvips/libvips/releases/tag/v8.8.0
      !Vips::respond_to?(:vips_foreign_get_suffixes)
    end

    def open_uri_tempfile?(path)
      # When trying to open urls for 'large' images, OpenURI will return a
      # tempfile. That tempfile does not have an extension indicating the type
      # of file. However, Vips will be able to process it anyway.
      # The 'large' file value is derived from OpenUri::Buffer class (> 10ko)
      path.split('/').last.starts_with?("open-uri")
    end

    def valid_image?(image)
      return false unless image

      vips_image_processor? && image.is_a?(Vips::Image) ? image.avg : image.valid?
    rescue exception_class
      false
    end

    def rotated_image?(image)
      if vips_image_processor? && image.is_a?(Vips::Image)
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
        io = file.fetch(:io)
        if io.is_a?(StringIO)
          tempfile = Tempfile.new([File.basename(file[:filename], '.*'), File.extname(file[:filename])])
          tempfile.binmode
          IO.copy_stream(io, tempfile)
          io.rewind
          tempfile.flush
          tempfile.rewind
          tempfile.path
        else
          File.open(io).path
        end
      else
        raise "Something wrong with params."
      end
    end

    def logger
      Rails.logger
    end

  end
end
