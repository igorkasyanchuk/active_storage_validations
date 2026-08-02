# frozen_string_literal: true

module ActiveStorageValidations
  # This analyzer relies on the third-party {MiniMagick}[https://github.com/minimagick/minimagick] gem
  # only to resolve the ImageMagick / GraphicsMagick +identify+ argv. Commands are executed through
  # {ASVCommandable#run_command} so +command_timeout+ can kill hung processes.
  # MiniMagick requires the {ImageMagick}[http://www.imagemagick.org] system library.
  # This is the default Rails image analyzer.
  class Analyzer::ImageAnalyzer::ImageMagick < Analyzer::ImageAnalyzer
    ImageInfo = Struct.new(:width, :height, :orientation, keyword_init: true) do
      def valid?
        width.to_i.positive? && height.to_i.positive?
      end

      def [](key)
        orientation if key == "%[orientation]"
      end
    end

    private

    def read_media
      Tempfile.create(binmode: true) do |tempfile|
        begin
          info = media(tempfile)
          if info&.valid?
            yield info
          else
            logger.info "Skipping image analysis because ImageMagick doesn't support the file"
            {}
          end
        ensure
          tempfile.close
        end
      end
    rescue Errno::ENOENT
      logger.info "Skipping image analysis because ImageMagick isn't installed"
      {}
    end

    def media_from_path(path)
      instrument("mini_magick") do |payload|
        result = run_command(*identify_command(path), payload: payload)
        return nil unless result.success?

        parse_identify_output(result.stdout)
      end
    end

    def identify_command(path)
      tool = MiniMagick::Tool.new("identify")
      tool.format("%w\t%h\t%[orientation]")
      tool << path
      tool.command
    end

    def parse_identify_output(stdout)
      width, height, orientation = stdout.to_s.strip.split("\t", 3)
      ImageInfo.new(
        width: width.to_i,
        height: height.to_i,
        orientation: orientation.to_s
      )
    end

    def rotated_image?(image)
      %w[ RightTop LeftBottom TopRight BottomLeft ].include?(image["%[orientation]"])
    end

    def supported?
      require "mini_magick"
      true
    rescue LoadError
      logger.info "Skipping image analysis because the mini_magick gem isn't installed"
      false
    end
  end
end
