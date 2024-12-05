# frozen_string_literal: true

require 'open3'

module ActiveStorageValidations
  # = ActiveStorageValidations Video \Analyzer
  #
  # Extracts the following from a video attachable:
  #
  # * Width (pixels)
  # * Height (pixels)
  # * Duration (seconds)
  # * Angle (degrees)
  # * Audio (true if file has an audio channel, false if not)
  # * Video (true if file has an video channel, false if not)
  #
  # Example:
  #
  #   ActiveStorageValidations::Analyzer::VideoAnalyzer.new(attachable).metadata
  #   # => { width: 640, height: 480, duration: 5.0, angle: 0, audio: true, video: true }
  #
  # When a video's angle is 90, -90, 270 or -270 degrees, its width and height are automatically swapped for convenience.
  #
  # This analyzer requires the {FFmpeg}[https://www.ffmpeg.org] system library, which is not provided by \Rails.
  class Analyzer::VideoAnalyzer < Analyzer
    def metadata
      read_media do |media|
        {
          width: Integer(width),
          height: Integer(height),
          duration: duration,
          angle: angle,
          audio: audio?,
          video: video?
        }.compact
      end
    end

    private

    def read_media
      Tempfile.create(binmode: true) do |tempfile|
        begin
          if media(tempfile).present?
            yield media(tempfile)
          else
            logger.info "Skipping image analysis because ImageMagick doesn't support the file"
            {}
          end
        ensure
          tempfile.close
        end
      end
    rescue Errno::ENOENT
      logger.info "Skipping video analysis because ffprobe isn't installed"
      {}
    end

    def media_from_path(path)
      instrument(File.basename(ffprobe_path)) do
        stdout, stderr, status = Open3.capture3(
          ffprobe_path,
          "-print_format", "json",
          "-show_streams",
          "-show_format",
          "-v", "error",
          path
        )

        if status.success?
          JSON.parse(stdout)
        else
          # FFprobe returns an stderr when the file is not valid or not a video.
          logger.info "Skipping video analysis because FFprobe doesn't support the file"
          nil
        end
      end
    end

    def ffprobe_path
      ActiveStorage.paths[:ffprobe] || "ffprobe"
    end

    def width
      if rotated?
        computed_height || encoded_height
      else
        encoded_width
      end
    end

    def height
      if rotated?
        encoded_width
      else
        computed_height || encoded_height
      end
    end

    def duration
      duration = video_stream["duration"] || container["duration"]
      Float(duration) if duration
    end

    def angle
      if tags["rotate"]
        Integer(tags["rotate"])
      elsif display_matrix && display_matrix["rotation"]
        Integer(display_matrix["rotation"])
      end
    end

    def display_matrix
      side_data.detect { |data| data["side_data_type"] == "Display Matrix" }
    end

    def display_aspect_ratio
      if descriptor = video_stream["display_aspect_ratio"]
        if terms = descriptor.split(":", 2)
          numerator   = Integer(terms[0])
          denominator = Integer(terms[1])

          [numerator, denominator] unless numerator == 0
        end
      end
    end

    def rotated?
      angle == 90 || angle == 270 || angle == -90 || angle == -270
    end

    def audio?
      audio_stream.present?
    end

    def video?
      video_stream.present?
    end

    def computed_height
      if encoded_width && display_height_scale
        encoded_width * display_height_scale
      end
    end

    def encoded_width
      @encoded_width ||= Float(video_stream["width"]) if video_stream["width"]
    end

    def encoded_height
      @encoded_height ||= Float(video_stream["height"]) if video_stream["height"]
    end

    def display_height_scale
      @display_height_scale ||= Float(display_aspect_ratio.last) / display_aspect_ratio.first if display_aspect_ratio
    end

    def tags
      @tags ||= video_stream["tags"] || {}
    end

    def side_data
      @side_data ||= video_stream["side_data_list"] || {}
    end

    def video_stream
      @video_stream ||= streams.detect { |stream| stream["codec_type"] == "video" } || {}
    end

    def audio_stream
      @audio_stream ||= streams.detect { |stream| stream["codec_type"] == "audio" } || {}
    end

    def streams
      @streams ||= @media["streams"] || []
    end

    def container
      @container ||= @media["format"] || {}
    end
  end
end