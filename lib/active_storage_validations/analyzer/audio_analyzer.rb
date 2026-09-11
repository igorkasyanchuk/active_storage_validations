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
      read_media do |media|
        {
          duration: duration,
          bit_rate: bit_rate,
          sample_rate: sample_rate,
          audio: audio?
        }.compact
      end
    end

    private

    def audio?
      audio_stream.present?
    end

    # Matroska / WebM (e.g. browser MediaRecorder output) report the duration
    # on the container only, not on the audio stream.
    def duration
      duration = audio_stream["duration"] || container["duration"]
      Float(duration).round(1) if duration
    end

    def bit_rate
      bit_rate = audio_stream["bit_rate"]
      Integer(bit_rate) if bit_rate
    end

    def sample_rate
      sample_rate = audio_stream["sample_rate"]
      Integer(sample_rate) if sample_rate
    end
  end
end
