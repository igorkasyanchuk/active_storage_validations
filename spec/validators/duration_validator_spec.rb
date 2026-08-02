# frozen_string_literal: true

require "rails_helper"

RSpec.describe ActiveStorageValidations::DurationValidator do
  let(:validator_test_class) { Duration::Validator }
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
      let(:file_having_lower_than_less_than_option) { audio_1s }
      let(:file_having_exact_less_than_option) { audio_2s }
      let(:file_having_higher_than_less_than_option) { audio_5s }
      let(:error_name) { "duration_not_less_than" }
      let(:error_options_for_file_having_exact_less_than_option) do
        {
          duration: "2 seconds",
          filename: file_having_exact_less_than_option[:filename],
          min: nil,
          max: "2 seconds"
        }
      end
      let(:error_options_for_file_having_higher_than_less_than_option) do
        {
          duration: "5 seconds",
          filename: file_having_higher_than_less_than_option[:filename],
          min: nil,
          max: "2 seconds"
        }
      end

      it_behaves_like "comparison less_than option"
    end

    describe ":less_than_or_equal_to" do
      let(:file_having_lower_than_less_than_or_equal_to_option) { audio_1s }
      let(:file_having_exact_less_than_or_equal_to_option) { audio_2s }
      let(:file_having_higher_than_less_than_or_equal_to_option) { audio_5s }
      let(:error_name) { "duration_not_less_than_or_equal_to" }
      let(:error_options_for_file_having_exact_less_than_or_equal_to_option) do
        {
          duration: "2 seconds",
          filename: file_having_exact_less_than_or_equal_to_option[:filename],
          min: nil,
          max: "2 seconds"
        }
      end
      let(:error_options_for_file_having_higher_than_less_than_or_equal_to_option) do
        {
          duration: "5 seconds",
          filename: file_having_higher_than_less_than_or_equal_to_option[:filename],
          min: nil,
          max: "2 seconds"
        }
      end

      it_behaves_like "comparison less_than_or_equal_to option"
    end

    describe ":greater_than" do
      let(:file_having_lower_than_greater_than_option) { audio_1s }
      let(:file_having_exact_greater_than_option) { audio_7s }
      let(:file_having_higher_than_greater_than_option) { audio_10s }
      let(:error_name) { "duration_not_greater_than" }
      let(:error_options_for_file_having_lower_than_greater_than_option) do
        {
          duration: "1 second",
          filename: file_having_lower_than_greater_than_option[:filename],
          min: "7 seconds",
          max: nil
        }
      end
      let(:error_options_for_file_having_exact_greater_than_option) do
        {
          duration: "7 seconds",
          filename: file_having_exact_greater_than_option[:filename],
          min: "7 seconds",
          max: nil
        }
      end

      it_behaves_like "comparison greater_than option"
    end

    describe ":greater_than_or_equal_to" do
      let(:file_having_lower_than_greater_than_or_equal_to_option) { audio_1s }
      let(:file_having_exact_greater_than_or_equal_to_option) { audio_7s }
      let(:file_having_higher_than_greater_than_or_equal_to_option) { audio_10s }
      let(:error_name) { "duration_not_greater_than_or_equal_to" }
      let(:error_options_for_file_having_lower_than_greater_than_or_equal_to_option) do
        {
          duration: "1 second",
          filename: file_having_lower_than_greater_than_or_equal_to_option[:filename],
          min: "7 seconds",
          max: nil
        }
      end

      it_behaves_like "comparison greater_than_or_equal_to option"
    end

    describe ":between" do
      let(:file_having_lower_than_lower_bound_between_option) { audio_1s }
      let(:file_having_exact_lower_bound_between_option) { audio_2s }
      let(:file_having_between_bounds_between_option) { audio_5s }
      let(:file_having_exact_higher_bound_between_option) { audio_7s }
      let(:file_having_higher_than_higher_bound_between_option) { audio_10s }
      let(:error_name) { "duration_not_between" }
      let(:error_options_for_file_having_lower_than_lower_bound_between_option) do
        {
          duration: "1 second",
          filename: file_having_lower_than_lower_bound_between_option[:filename],
          min: "2 seconds",
          max: "7 seconds"
        }
      end
      let(:error_options_for_file_having_higher_than_higher_bound_between_option) do
        {
          duration: "10 seconds",
          filename: file_having_higher_than_higher_bound_between_option[:filename],
          min: "2 seconds",
          max: "7 seconds"
        }
      end

      it_behaves_like "comparison between option"
    end

    describe ":equal_to" do
      let(:file_having_lower_than_equal_to_option) { audio_2s }
      let(:file_having_exact_equal_to_option) { audio_5s }
      let(:file_having_higher_than_equal_to_option) { audio_7s }
      let(:error_name) { "duration_not_equal_to" }
      let(:error_options_for_file_having_lower_than_equal_to_option) do
        {
          duration: "2 seconds",
          filename: file_having_lower_than_equal_to_option[:filename],
          exact: "5 seconds"
        }
      end
      let(:error_options_for_file_having_higher_than_equal_to_option) do
        {
          duration: "7 seconds",
          filename: file_having_higher_than_equal_to_option[:filename],
          exact: "5 seconds"
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
        let(:attribute) { :less_than }
        let(:file_for_attachment_missing) { audio_1s }

        it_behaves_like "reports attachment_missing"
      end
    end
  end

  describe "Blob Metadata" do
    let(:attachable) do
      {
        io: File.open(Rails.root.join("public", "audio.mp3")),
        filename: "audio.mp3",
        content_type: "audio/mp3"
      }
    end

    it_behaves_like "is performance optimized"
  end

  describe "Rails options" do
    it_behaves_like "works with all rails common validation options"
  end
end
