# frozen_string_literal: true

require_relative "shared/asv_ff_probable"

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
    include ASVFFProbable

    def metadata
      read_media { |_media| metadata_from_streams }
    end

    private

    # ffprobe can exit 0 on a well-formed container with zero streams (empty
    # MP4/M4A). Hash#compact keeps false, so { audio: false, video: false }
    # would be memoized and processable_file would treat it as a successful
    # decode. {} is the documented "no analysis" miss.
    def metadata_from_streams
      return {} unless audio? || video?

      {
        width: (Integer(width) if width),
        height: (Integer(height) if height),
        duration: duration,
        angle: angle,
        audio: audio?,
        video: video?
      }.compact
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

    # Round to milliseconds so 1.96s is not stored as 2.0 (which made
    # `less_than: 2.seconds` fail).
    def duration
      parse_float(video_stream["duration"] || container["duration"])&.round(3)
    end

    # ffprobe reports the rotation either as a stream tag (older encoders) or as
    # Display Matrix side data. Encoders write it as "90", "90.0" or "-89.9"
    # indifferently, so parse it as a float and round; an unparsable value
    # means no known rotation rather than an exception escaping `valid?`.
    def angle
      parse_float(tags["rotate"] || display_matrix&.dig("rotation"))&.round
    end

    def display_matrix
      side_data.detect { |data| data["side_data_type"] == "Display Matrix" }
    end

    def display_aspect_ratio
      descriptor = video_stream["display_aspect_ratio"]
      return unless descriptor

      terms = descriptor.to_s.split(":", 2)
      numerator = parse_integer(terms[0])
      denominator = parse_integer(terms[1])
      return if numerator.nil? || denominator.nil? || numerator.zero?

      [ numerator, denominator ]
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
      @encoded_width ||= parse_float(video_stream["width"])
    end

    def encoded_height
      @encoded_height ||= parse_float(video_stream["height"])
    end

    def display_height_scale
      return unless display_aspect_ratio

      last = parse_float(display_aspect_ratio.last)
      @display_height_scale ||= last / display_aspect_ratio.first if last
    end

    def tags
      @tags ||= video_stream["tags"] || {}
    end

    # ffprobe reports an Array of hashes. Default to [] (Rails does the same)
    # so Enumerable#detect yields those hashes. A Hash default made detect
    # yield [key, value] pairs and could raise TypeError from valid?.
    def side_data
      list = video_stream["side_data_list"]
      @side_data ||= list.is_a?(Array) ? list : []
    end
  end
end
