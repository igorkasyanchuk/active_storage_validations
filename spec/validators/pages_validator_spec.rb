# frozen_string_literal: true

require "rails_helper"

RSpec.describe ActiveStorageValidations::PagesValidator do
  let(:validator_test_class) { Pages::Validator }
  let(:params) { {} }

  describe "ASVAttachable shared behavior" do
    it_behaves_like "ASVAttachable"
  end

  describe "#initialize_error_options" do
    it_behaves_like "ASVErrorable"
  end

  describe "#check_validity!" do
    it_behaves_like "checks validator validity"
  end

  describe "Validator checks" do
    let(:model) { validator_test_class::Check.new(params) }

    it_behaves_like "works fine with attachables"


    describe ":less_than" do
      let(:file_having_lower_than_less_than_option) { pdf_1_page_file }
      let(:file_having_exact_less_than_option) { pdf_2_pages_file }
      let(:file_having_higher_than_less_than_option) { pdf_5_pages_file }
      let(:error_name) { "pages_not_less_than" }
      let(:error_options_for_file_having_exact_less_than_option) do
        {
          pages: "2",
          filename: file_having_exact_less_than_option[:filename],
          min: nil,
          max: "2"
        }
      end
      let(:error_options_for_file_having_higher_than_less_than_option) do
        {
          pages: "5",
          filename: file_having_higher_than_less_than_option[:filename],
          min: nil,
          max: "2"
        }
      end

      it_behaves_like "comparison less_than option"
    end

    describe ":less_than_or_equal_to" do
      let(:file_having_lower_than_less_than_or_equal_to_option) { pdf_1_page_file }
      let(:file_having_exact_less_than_or_equal_to_option) { pdf_2_pages_file }
      let(:file_having_higher_than_less_than_or_equal_to_option) { pdf_5_pages_file }
      let(:error_name) { "pages_not_less_than_or_equal_to" }
      let(:error_options_for_file_having_exact_less_than_or_equal_to_option) do
        {
          pages: "2",
          filename: file_having_exact_less_than_or_equal_to_option[:filename],
          min: nil,
          max: "2"
        }
      end
      let(:error_options_for_file_having_higher_than_less_than_or_equal_to_option) do
        {
          pages: "5",
          filename: file_having_higher_than_less_than_or_equal_to_option[:filename],
          min: nil,
          max: "2"
        }
      end

      it_behaves_like "comparison less_than_or_equal_to option"
    end

    describe ":greater_than" do
      let(:file_having_lower_than_greater_than_option) { pdf_1_page_file }
      let(:file_having_exact_greater_than_option) { pdf_7_pages_file }
      let(:file_having_higher_than_greater_than_option) { pdf_10_pages_file }
      let(:error_name) { "pages_not_greater_than" }
      let(:error_options_for_file_having_lower_than_greater_than_option) do
        {
          pages: "1",
          filename: file_having_lower_than_greater_than_option[:filename],
          min: "7",
          max: nil
        }
      end
      let(:error_options_for_file_having_exact_greater_than_option) do
        {
          pages: "7",
          filename: file_having_exact_greater_than_option[:filename],
          min: "7",
          max: nil
        }
      end

      it_behaves_like "comparison greater_than option"
    end

    describe ":greater_than_or_equal_to" do
      let(:file_having_lower_than_greater_than_or_equal_to_option) { pdf_1_page_file }
      let(:file_having_exact_greater_than_or_equal_to_option) { pdf_7_pages_file }
      let(:file_having_higher_than_greater_than_or_equal_to_option) { pdf_10_pages_file }
      let(:error_name) { "pages_not_greater_than_or_equal_to" }
      let(:error_options_for_file_having_lower_than_greater_than_or_equal_to_option) do
        {
          pages: "1",
          filename: file_having_lower_than_greater_than_or_equal_to_option[:filename],
          min: "7",
          max: nil
        }
      end

      it_behaves_like "comparison greater_than_or_equal_to option"
    end

    describe ":between" do
      let(:file_having_lower_than_lower_bound_between_option) { pdf_1_page_file }
      let(:file_having_exact_lower_bound_between_option) { pdf_2_pages_file }
      let(:file_having_between_bounds_between_option) { pdf_5_pages_file }
      let(:file_having_exact_higher_bound_between_option) { pdf_7_pages_file }
      let(:file_having_higher_than_higher_bound_between_option) { pdf_10_pages_file }
      let(:error_name) { "pages_not_between" }
      let(:error_options_for_file_having_lower_than_lower_bound_between_option) do
        {
          pages: "1",
          filename: file_having_lower_than_lower_bound_between_option[:filename],
          min: "2",
          max: "7"
        }
      end
      let(:error_options_for_file_having_higher_than_higher_bound_between_option) do
        {
          pages: "10",
          filename: file_having_higher_than_higher_bound_between_option[:filename],
          min: "2",
          max: "7"
        }
      end

      it_behaves_like "comparison between option"
    end

    describe ":equal_to" do
      let(:file_having_lower_than_equal_to_option) { pdf_1_page_file }
      let(:file_having_exact_equal_to_option) { pdf_5_pages_file }
      let(:file_having_higher_than_equal_to_option) { pdf_7_pages_file }
      let(:error_name) { "pages_not_equal_to" }
      let(:error_options_for_file_having_lower_than_equal_to_option) do
        {
          pages: "1",
          filename: file_having_lower_than_equal_to_option[:filename],
          exact: "5"
        }
      end
      let(:error_options_for_file_having_higher_than_equal_to_option) do
        {
          pages: "7",
          filename: file_having_higher_than_equal_to_option[:filename],
          exact: "5"
        }
      end

      it_behaves_like "comparison equal_to option"
    end

    describe "Edge cases" do
      context "when the passed file is not a valid media" do
        subject(:record) { model.public_send(attribute).attach(empty_io_file) and model }

        let(:attribute) { :with_invalid_media_file }
        let(:error_options) do
          {
            filename: empty_io_file[:filename]
          }
        end

        it { is_expected_not_to_be_valid }
        it { is_expected_to_include_error_message("media_metadata_missing", error_options: error_options) }
        it { is_expected_to_have_error_options(error_options) }
      end

      describe "when the attached file is missing from storage" do
        let(:attribute) { :equal_to }
        let(:file_for_attachment_missing) { pdf_5_pages_file }

        it_behaves_like "reports attachment_missing"
      end
    end
  end

  describe "Blob Metadata" do
    let(:attachable) do
      {
        io: File.open(Rails.root.join("public", "pdf_5_pages.pdf")),
        filename: "pdf_5_pages.pdf",
        content_type: "application/pdf"
      }
    end

    it_behaves_like "is performance optimized"
  end

  describe "Rails options" do
    it_behaves_like "works with all rails common validation options"
  end
end
