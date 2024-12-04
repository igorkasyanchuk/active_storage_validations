# frozen_string_literal: true

require "test_helper"
require 'analyzers/support/analyzer_helpers'
require 'analyzers/shared_examples/returns_the_right_metadata_for_any_attachable'

describe ActiveStorageValidations::Analyzer::ImageAnalyzer::ImageMagick do
  include AnalyzerHelpers

  let(:analyzer_klass) { ActiveStorageValidations::Analyzer::ImageAnalyzer::ImageMagick }
  let(:analyzer) { analyzer_klass.new(attachable) }

  # Using a jpg file to test rotation because the behaviour is uniform among OS,
  # we tried doing it with a png file but the result was different
  # between our local machine and the CI.
  let(:media_extension) { '.png' }
  let(:media_extension_rotated) { '.jpg' }
  let(:media_filename) { "image_150x150#{media_extension}" }
  let(:media_filename_over_10ko) { "image_150x150_28ko#{media_extension}" }
  let(:media_filename_rotated) { "image_700x500_rotated_90#{media_extension_rotated}" }
  let(:media_filename_0ko) { "image_file_0ko#{media_extension}" }
  let(:media_path) { Rails.root.join('public', media_filename) }
  let(:media_io) { File.open(media_path) }
  let(:media_content_type) { 'image/png' }
  let(:media_content_type_rotated) { 'image/jpeg' }
  let(:expected_metadata) { { width: 150, height: 150 } }
  let(:expected_metadata_over_10ko) { { width: 150, height: 150 } }
  let(:expected_metadata_rotated) { { width: 700, height: 500 } }

  include ReturnsTheRightMetadataForAnyAttachable
end
