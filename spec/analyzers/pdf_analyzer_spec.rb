# frozen_string_literal: true

require "rails_helper"
require "analyzers/support/analyzer_helpers"

RSpec.describe ActiveStorageValidations::Analyzer::PdfAnalyzer do
  def self.test_rotatable_media?
    false
  end

  let(:analyzer) { described_class.new(attachable) }

  let(:media_extension) { ".pdf" }
  let(:media_filename) { "pdf_150x150#{media_extension}" }
  let(:media_filename_over_10ko) { "pdf_150x150_79ko#{media_extension}" }
  let(:media_filename_0ko) { "pdf_file_0ko#{media_extension}" }
  let(:media_path) { Rails.root.join("public", media_filename) }
  let(:media_io) { File.open(media_path) }
  let(:media_content_type) { "application/pdf" }
  let(:expected_metadata) { { width: 150, height: 150, pages: 1 } }
  let(:expected_metadata_over_10ko) { { width: 36, height: 36, pages: 1 } }

  it_behaves_like "returns the right metadata for any attachable"
  it_behaves_like "works fine with 2 pages pdf"

  describe "timeouts" do
    let(:path) { Rails.root.join("public", "pdf_150x150.pdf").to_s }
    let(:attachable) do
      {
        io: File.open(path),
        filename: "pdf_150x150.pdf",
        content_type: "application/pdf"
      }
    end
    let(:analyzer) { described_class.new(attachable, timeout: 0.2) }

    after { ActiveStorageValidations.command_timeout = 10.seconds }

    context "when the command times out" do
      subject(:media) { analyzer.send(:media_from_path, path) }

      before { allow(analyzer).to receive(:run_command).and_return(timed_out_command_result) }

      it "returns nil from media_from_path" do
        expect(media).to be_nil
      end
    end
  end
end
