# frozen_string_literal: true

require_relative "shared/asv_ff_probable"

module ActiveStorageValidations
  # = ActiveStorageValidations Audio \Analyzer
  #
  # Extracts the following from an audio attachable:
  #
  # * Duration (seconds)
  # * Bit rate (bits/s)
  # * Sample rate (hertz)
  # * Audio (true if file has an audio channel, false if not)
  #
  # Example:
  #
  #   ActiveStorageValidations::Analyzer::AudioAnalyzer.new(attachable).metadata
  #   # => { duration: 5.0, bit_rate: 320340, sample_rate: 44100, audio: true }
  #
  # Unlike Rails' own audio analyzer, stream tags (ID3 / Vorbis comments) are
  # not extracted: no validator reads them, and everything returned here is
  # cached on the blob's custom metadata, which Active Storage forwards to the
  # storage service (S3 caps object metadata at 2 KB and expects ASCII).
  #
  # This analyzer requires the {FFmpeg}[https://www.ffmpeg.org] system library, which is not provided by \Rails.
  class Analyzer::AudioAnalyzer < Analyzer
    include ASVFFProbable

    def metadata
      read_media { |_media| metadata_from_streams }
    end

    private

    # Same empty-container contract as VideoAnalyzer: a successful ffprobe
    # with no audio stream is not an analysis. Do not emit { audio: false }
    # (or a container duration) that processable_file / with_audio: false
    # would read as a decoded file with no track.
    def metadata_from_streams
      return {} unless audio?

      {
        duration: duration,
        bit_rate: bit_rate,
        sample_rate: sample_rate,
        audio: audio?
      }.compact
    end

    def audio?
      audio_stream.present?
    end

    # Matroska / WebM (e.g. browser MediaRecorder output) report the duration
    # on the container only, not on the audio stream. Round to milliseconds so
    # 1.96s is not stored as 2.0 (which made `less_than: 2.seconds` fail).
    def duration
      parse_float(audio_stream["duration"] || container["duration"])&.round(3)
    end

    def bit_rate
      parse_integer(audio_stream["bit_rate"])
    end

    def sample_rate
      parse_integer(audio_stream["sample_rate"])
    end
  end
end
