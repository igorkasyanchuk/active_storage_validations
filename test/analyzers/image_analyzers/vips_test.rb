# frozen_string_literal: true

require "test_helper"
require 'analyzers/support/analyzer_helpers'
require 'analyzers/image_analyzers/shared_examples/returns_the_right_metadata_for_any_attachable'

describe ActiveStorageValidations::Analyzer::ImageAnalyzer::Vips do
  include AnalyzerHelpers

  let(:analyzer_klass) { ActiveStorageValidations::Analyzer::ImageAnalyzer::Vips }
  let(:analyzer) { analyzer_klass.new(attachable) }

  # Uncomment these lines in development, or launch test with ENV['IMAGE_PROCESSOR'] = :vips
  # before do
  #   @original_variant_processor = Rails.application.config.active_storage.variant_processor
  #   Rails.application.config.active_storage.variant_processor = :vips
  #   ActiveStorage.variant_processor = :vips
  # end

  # after do
  #   Rails.application.config.active_storage.variant_processor = @original_variant_processor
  #   ActiveStorage.variant_processor = @original_variant_processor
  # end

  include ReturnsTheRightMetadataForAnyAttachable
end
