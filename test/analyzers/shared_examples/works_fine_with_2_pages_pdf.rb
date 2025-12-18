# frozen_string_literal: true

module WorksFineWith2PagesPdf
  extend ActiveSupport::Concern

  included do
    describe "working with 2 pages pdf with different dimensions" do
      subject { analyzer.metadata }

      let(:attachable) do
        {
          io: File.open(Rails.root.join("public", "pdf_150x150_2_pages.pdf")),
          filename: "pdf_150x150_2_pages.pdf",
          content_type: "application/pdf"
        }
      end
      let(:expected_metadata) { { width: 150, height: 150, pages: 2 } }

      it "validates the dimensions of the first page only" do
        assert_equal(expected_metadata, subject)
      end
    end

    describe "working with a pdf with decimal dimensions" do
      subject { analyzer.metadata }

      let(:attachable) do
        {
          io: File.open(Rails.root.join("public", "pdf_123.4x200.7.pdf")),
          filename: "pdf_123.4x200.7.pdf",
          content_type: "application/pdf"
        }
      end

      let(:expected_metadata) { { width: 123, height: 200, pages: 1 } }

      it "correctly reports decimal dimensions" do
        assert_equal(expected_metadata, subject)
      end
    end
  end
end
