# frozen_string_literal: true

RSpec.shared_examples "works fine with 2 pages pdf" do
  describe "working with 2 pages pdf with different dimensions" do
    subject(:metadata) { analyzer.metadata }

    let(:attachable) do
      {
        io: open_fixture(Rails.root.join("public", "pdf_150x150_2_pages.pdf")),
        filename: "pdf_150x150_2_pages.pdf",
        content_type: "application/pdf"
      }
    end
    let(:expected_metadata) { { width: 150, height: 150, pages: 2 } }

    it "validates the dimensions of the first page only" do
      expect(metadata).to eq(expected_metadata)
    end
  end

  describe "working with a pdf with decimal dimensions" do
    subject(:metadata) { analyzer.metadata }

    let(:attachable) do
      {
        io: open_fixture(Rails.root.join("public", "pdf_123.4x200.7.pdf")),
        filename: "pdf_123.4x200.7.pdf",
        content_type: "application/pdf"
      }
    end

    let(:expected_metadata) { { width: 123, height: 200, pages: 1 } }

    it "correctly reports decimal dimensions" do
      expect(metadata).to eq(expected_metadata)
    end
  end

  describe "working with an A4 pdf (two or more fractional digits)" do
    subject(:metadata) { analyzer.metadata }

    let(:attachable) do
      {
        io: open_fixture(Rails.root.join("public", "most_common_mime_types", "example.pdf")),
        filename: "example.pdf",
        content_type: "application/pdf"
      }
    end

    let(:expected_metadata) { { width: 595, height: 841, pages: 1 } }

    it "reports the first-page size without splitting extra fractional digits" do
      expect(metadata).to eq(expected_metadata)
    end
  end
end
