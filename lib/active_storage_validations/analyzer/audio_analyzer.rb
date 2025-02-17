# frozen_string_literal: true

require "open3"
require_relative "shared/asv_ff_probable"

module ActiveStorageValidations
  # = ActiveStorageValidations Audio \Analyzer
  #
  # Extracts the following from an audio attachable:
  #
  # * Duration (seconds)
  # * Bit rate (bits/s)
  # * Sample rate (hertz)
  # * Tags (internal metadata)
  #
  # Example:
  #
  #   ActiveStorageValidations::Analyzer::AudioAnalyzer.new(attachable).metadata
  #   # => { duration: 5.0, bit_rate: 320340, sample_rate: 44100, tags: { encoder: "Lavc57.64", ... } }
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
          tags: tags
        }.compact
      end
    end

    private

    def duration
      duration = audio_stream["duration"]
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

    def tags
      tags = audio_stream["tags"]
      Hash(tags) if tags
    end
  end
end
