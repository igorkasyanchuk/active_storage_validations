# frozen_string_literal: true

require "test_helper"
require 'analyzers/support/analyzer_helpers'
require 'analyzers/shared_examples/returns_the_right_metadata_for_any_attachable'

describe ActiveStorageValidations::Analyzer::VideoAnalyzer do
  include AnalyzerHelpers

  let(:analyzer_klass) { ActiveStorageValidations::Analyzer::VideoAnalyzer }
  let(:analyzer) { analyzer_klass.new(attachable) }

  let(:media_extension) { '.mp4' }
  let(:media_filename) { "video_150x150#{media_extension}" }
  let(:media_filename_over_10ko) { "video_150x150_24ko#{media_extension}" }
  let(:media_filename_rotated) { "video_700x500_rotated_90#{media_extension}" }
  let(:media_filename_0ko) { "video_file_0ko#{media_extension}" }
  let(:media_path) { Rails.root.join('public', media_filename) }
  let(:media_io) { File.open(media_path) }
  let(:media_content_type) { 'video/mp4' }
  let(:media_content_type_rotated) { media_content_type }
  let(:expected_metadata) { { width: 150, height: 150, duration: 1.733333, audio: false, video: true } }
  let(:expected_metadata_over_10ko) { { width: 150, height: 150, duration: 9.642967, audio: false, video: true } }
  let(:expected_metadata_rotated) { { width: 700, height: 500, duration: 1.733333, audio: false, video: true } }

  include ReturnsTheRightMetadataForAnyAttachable
end
