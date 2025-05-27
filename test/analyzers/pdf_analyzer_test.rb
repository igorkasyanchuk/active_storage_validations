# frozen_string_literal: true

require "test_helper"
require "analyzers/support/analyzer_helpers"
require "analyzers/shared_examples/returns_the_right_metadata_for_any_attachable"
require "analyzers/shared_examples/works_fine_with_2_pages_pdf"

describe ActiveStorageValidations::Analyzer::PdfAnalyzer do
  include AnalyzerHelpers

  def self.test_rotatable_media?
    false
  end

  let(:analyzer_klass) { ActiveStorageValidations::Analyzer::PdfAnalyzer }
  let(:analyzer) { analyzer_klass.new(attachable) }

  let(:media_extension) { ".pdf" }
  let(:media_filename) { "pdf_150x150#{media_extension}" }
  let(:media_filename_over_10ko) { "pdf_150x150_79ko#{media_extension}" }
  let(:media_filename_0ko) { "pdf_file_0ko#{media_extension}" }
  let(:media_path) { Rails.root.join("public", media_filename) }
  let(:media_io) { File.open(media_path) }
  let(:media_content_type) { "application/pdf" }
  let(:expected_metadata) { { width: 150, height: 150, pages: 1 } }
  let(:expected_metadata_over_10ko) { { width: 36, height: 36, pages: 1 } }

  include ReturnsTheRightMetadataForAnyAttachable
  include WorksFineWith2PagesPdf
end
