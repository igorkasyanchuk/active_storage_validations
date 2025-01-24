# frozen_string_literal: true

module ActiveStorageValidations
  # ActiveStorageValidations:::ASVFFProbable
  #
  # Validator helper methods for analyzers using FFprobe.
  module ASVFFProbable
    extend ActiveSupport::Concern

    private

    def read_media
      Tempfile.create(binmode: true) do |tempfile|
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
      instrument(File.basename(ffprobe_path)) do
        stdout, _stderr, status = Open3.capture3(
          ffprobe_path,
          "-print_format", "json",
          "-show_streams",
          "-show_format",
          "-v", "error",
          path
        )

        status.success? ? JSON.parse(stdout) : nil
      end
    end

    def ffprobe_path
      ActiveStorage.paths[:ffprobe] || "ffprobe"
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
  end
end
