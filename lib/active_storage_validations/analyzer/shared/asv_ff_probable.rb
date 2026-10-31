# frozen_string_literal: true

require "json"

module ActiveStorageValidations
  # ActiveStorageValidations:::ASVFFProbable
  #
  # Validator helper methods for analyzers using FFprobe.
  module ASVFFProbable
    extend ActiveSupport::Concern

    private

    def read_media
      create_media_tempfile do |tempfile|
        begin
          if media(tempfile).present?
            yield media(tempfile)
          else
            logger.info "Skipping file metadata analysis because ffprobe doesn't support the file"
            {}
          end
        ensure
          tempfile.close
        end
      end
    rescue Errno::ENOENT
      logger.info "Skipping file metadata analysis because ffprobe isn't installed"
      {}
    end

    def media_from_path(path)
      instrument(File.basename(ffprobe_path)) do |payload|
        result = run_command(
          ffprobe_path,
          "-print_format", "json",
          "-show_streams",
          "-show_format",
          "-v", "error",
          path,
          payload: payload
        )

        parse_ffprobe_json(result)
      end
    end

    def parse_ffprobe_json(result)
      return nil unless result.success?

      JSON.parse(result.stdout)
    rescue JSON::ParserError
      nil
    end

    def parse_float(value)
      Float(value) if value
    rescue ArgumentError, TypeError
      nil
    end

    def parse_integer(value)
      Integer(value) if value
    rescue ArgumentError, TypeError
      nil
    end

    def ffprobe_path
      ActiveStorage.paths[:ffprobe] || "ffprobe"
    end

    # Cover art (ID3 / MP4 artwork) is reported as a video stream flagged
    # disposition.attached_pic. It is a still image, not a video track: an
    # audio-only MP4 with a 1920x1080 cover must not report video dimensions.
    def video_stream
      @video_stream ||= streams.detect { |stream| stream["codec_type"] == "video" && !attached_pic?(stream) } || {}
    end

    def attached_pic?(stream)
      stream.dig("disposition", "attached_pic").to_i == 1
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
