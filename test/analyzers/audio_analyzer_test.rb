# frozen_string_literal: true

require "test_helper"
require "analyzers/support/analyzer_helpers"
require "analyzers/shared_examples/returns_the_right_metadata_for_any_attachable"

describe ActiveStorageValidations::Analyzer::AudioAnalyzer do
  include AnalyzerHelpers

  def self.test_rotatable_media?
    true
  end

  let(:analyzer_klass) { ActiveStorageValidations::Analyzer::AudioAnalyzer }
  let(:analyzer) { analyzer_klass.new(attachable) }

  let(:media_extension) { ".mp3" }
  let(:media_filename) { "audio#{media_extension}" }
  let(:media_filename_over_10ko) { "audio_2s#{media_extension}" }
  let(:media_filename_rotated) { "audio#{media_extension}" }
  let(:media_filename_0ko) { "audio_0ko#{media_extension}" }
  let(:media_path) { Rails.root.join("public", media_filename) }
  let(:media_io) { File.open(media_path) }
  let(:media_content_type) { "audio/mp3" }
  let(:media_content_type_rotated) { media_content_type }
  let(:expected_metadata) { { duration: 1.0, bit_rate: 32000, sample_rate: 44100, tags: { "encoder" => "Lavc60.3." } } }
  let(:expected_metadata_over_10ko) { { duration: 2.0, bit_rate: 107286, sample_rate: 44100, tags: { "encoder" => "LAME3.100" } } }
  let(:expected_metadata_rotated) { { duration: 1.0, bit_rate: 32000, sample_rate: 44100, tags: { "encoder" => "Lavc60.3." } } }

  include ReturnsTheRightMetadataForAnyAttachable
end
