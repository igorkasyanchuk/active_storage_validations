# frozen_string_literal: true

require "test_helper"
require 'analyzers/support/analyzer_helpers'
require 'analyzers/image_analyzers/shared_examples/accepts_only_image_media'
require 'analyzers/image_analyzers/shared_examples/returns_the_right_metadata_for_any_attachable'

describe ActiveStorageValidations::Analyzer::ImageAnalyzer::ImageMagick do
  include AnalyzerHelpers

  let(:analyzer_klass) { ActiveStorageValidations::Analyzer::ImageAnalyzer::ImageMagick }
  let(:analyzer) { analyzer_klass.new(attachable) }

  include AcceptsOnlyImageMedia
  include ReturnsTheRightMetadataForAnyAttachable
end
