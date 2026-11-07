# frozen_string_literal: true

require "json"

module ActiveStorageValidations
  # ActiveStorageValidations:::ASVFFProbable
  #
  # Validator helper methods for analyzers using FFprobe.
  module ASVFFProbable
    extend ActiveSupport::Concern

    # Formats whose file only lists other media (a playlist, a concat list):
    # ffprobe follows the entries, so an uploaded text file would be measured
    # as a local file of the server it points to.
    PLAYLIST_FORMATS = %w[hls dash concat].freeze

    private

    def read_media
      create_media_tempfile do |tempfile|
        begin
          if playlist?(media(tempfile))
            logger.info "Skipping file metadata analysis because the file is a playlist (#{media(tempfile).dig("format", "format_name")})"
            {}
          elsif media(tempfile).present?
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

    def playlist?(media)
      return false unless media.is_a?(Hash)

      (media.dig("format", "format_name").to_s.split(",") & PLAYLIST_FORMATS).any?
    end

    def media_from_path(path)
      @media_path = path
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

    # The longest of the container, the audio track and the video track. A
    # file plays until its last track ends: a 0.04s video track next to a 30s
    # audio track must not pass `less_than: 10.seconds`. Matroska / WebM (e.g.
    # browser MediaRecorder output) report the duration on the container only.
    # Round to milliseconds so 1.96s is not stored as 2.0 (which made
    # `less_than: 2.seconds` fail).
    def media_duration
      [ container, audio_stream, video_stream ].filter_map { |source| parse_float(source["duration"]) }.max&.round(3) ||
        packet_duration
    end

    # Browser MediaRecorder WebM files have no Duration element (nor Cues):
    # ffprobe reports no duration at all and `duration` rejected every
    # recording with media_metadata_missing. Measure the end of the last
    # packet instead (demuxing only, under the same timeout).
    def packet_duration
      return unless @media_path

      result = instrument(File.basename(ffprobe_path)) do |payload|
        run_command(ffprobe_path, "-v", "error", "-show_entries", "packet=pts_time,duration_time", "-of", "csv=p=0", @media_path, payload: payload)
      end
      return unless result&.success?

      result.stdout.each_line.filter_map do |line|
        pts, duration = line.split(",", 3)
        start = parse_float(pts)
        start + (parse_float(duration) || 0) if start
      end.max&.round(3)
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
