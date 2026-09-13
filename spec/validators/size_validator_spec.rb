# frozen_string_literal: true

require "rails_helper"

RSpec.describe ActiveStorageValidations::SizeValidator do
  let(:validator_test_class) { Size::Validator }
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

    describe ":less_than" do
      let(:file_having_lower_than_less_than_option) { file_1ko }
      let(:file_having_exact_less_than_option) { file_2ko }
      let(:file_having_higher_than_less_than_option) { file_5ko }
      let(:error_name) { "file_size_not_less_than" }
      let(:error_options_for_file_having_exact_less_than_option) do
        {
          file_size: "2 KB",
          filename: file_having_exact_less_than_option[:filename],
          min: nil,
          max: "2 KB"
        }
      end
      let(:error_options_for_file_having_higher_than_less_than_option) do
        {
          file_size: "5 KB",
          filename: file_having_higher_than_less_than_option[:filename],
          min: nil,
          max: "2 KB"
        }
      end

      it_behaves_like "comparison less_than option"
    end

    describe ":less_than_or_equal_to" do
      let(:file_having_lower_than_less_than_or_equal_to_option) { file_1ko }
      let(:file_having_exact_less_than_or_equal_to_option) { file_2ko }
      let(:file_having_higher_than_less_than_or_equal_to_option) { file_5ko }
      let(:error_name) { "file_size_not_less_than_or_equal_to" }
      let(:error_options_for_file_having_exact_less_than_or_equal_to_option) do
        {
          file_size: "2 KB",
          filename: file_having_exact_less_than_or_equal_to_option[:filename],
          min: nil,
          max: "2 KB"
        }
      end
      let(:error_options_for_file_having_higher_than_less_than_or_equal_to_option) do
        {
          file_size: "5 KB",
          filename: file_having_higher_than_less_than_or_equal_to_option[:filename],
          min: nil,
          max: "2 KB"
        }
      end

      it_behaves_like "comparison less_than_or_equal_to option"
    end

    describe ":greater_than" do
      let(:file_having_lower_than_greater_than_option) { file_1ko }
      let(:file_having_exact_greater_than_option) { file_7ko }
      let(:file_having_higher_than_greater_than_option) { file_10ko }
      let(:error_name) { "file_size_not_greater_than" }
      let(:error_options_for_file_having_lower_than_greater_than_option) do
        {
          file_size: "1 KB",
          filename: file_having_lower_than_greater_than_option[:filename],
          min: "7 KB",
          max: nil
        }
      end
      let(:error_options_for_file_having_exact_greater_than_option) do
        {
          file_size: "7 KB",
          filename: file_having_exact_greater_than_option[:filename],
          min: "7 KB",
          max: nil
        }
      end

      it_behaves_like "comparison greater_than option"
    end

    describe ":greater_than_or_equal_to" do
      let(:file_having_lower_than_greater_than_or_equal_to_option) { file_1ko }
      let(:file_having_exact_greater_than_or_equal_to_option) { file_7ko }
      let(:file_having_higher_than_greater_than_or_equal_to_option) { file_10ko }
      let(:error_name) { "file_size_not_greater_than_or_equal_to" }
      let(:error_options_for_file_having_lower_than_greater_than_or_equal_to_option) do
        {
          file_size: "1 KB",
          filename: file_having_lower_than_greater_than_or_equal_to_option[:filename],
          min: "7 KB",
          max: nil
        }
      end

      it_behaves_like "comparison greater_than_or_equal_to option"
    end

    describe ":between" do
      let(:file_having_lower_than_lower_bound_between_option) { file_1ko }
      let(:file_having_exact_lower_bound_between_option) { file_2ko }
      let(:file_having_between_bounds_between_option) { file_5ko }
      let(:file_having_exact_higher_bound_between_option) { file_7ko }
      let(:file_having_higher_than_higher_bound_between_option) { file_10ko }
      let(:error_name) { "file_size_not_between" }
      let(:error_options_for_file_having_lower_than_lower_bound_between_option) do
        {
          file_size: "1 KB",
          filename: file_having_lower_than_lower_bound_between_option[:filename],
          min: "2 KB",
          max: "7 KB"
        }
      end
      let(:error_options_for_file_having_higher_than_higher_bound_between_option) do
        {
          file_size: "10.2 KB",
          filename: file_having_higher_than_higher_bound_between_option[:filename],
          min: "2 KB",
          max: "7 KB"
        }
      end

      it_behaves_like "comparison between option"
    end

    describe "exclusive :between (e.g. between: 2.kilobytes...7.kilobytes)" do
      let(:attribute) { :between_exclusive }
      let(:error_options) do
        {
          file_size: "7 KB",
          filename: file_7ko[:filename],
          min: "2 KB",
          max: ActiveSupport::NumberHelper.number_to_human_size(7.kilobytes - 1)
        }
      end

      context "when provided with a file inside the exclusive range" do
        subject(:record) { model.public_send(attribute).attach(file_5ko) and model }

        it { is_expected_to_be_valid }
      end

      context "when provided with a file at the exclusive end bound" do
        subject(:record) { model.public_send(attribute).attach(file_7ko) and model }

        it { is_expected_not_to_be_valid }
        it { is_expected_to_include_error_message("file_size_not_between", with_locales: [ "en" ], error_options: error_options) }
        it { is_expected_to_have_error_options(error_options) }
      end
    end

    describe ":equal_to" do
      let(:file_having_lower_than_equal_to_option) { file_1ko }
      let(:file_having_exact_equal_to_option) { file_5ko }
      let(:file_having_higher_than_equal_to_option) { file_7ko }
      let(:error_name) { "file_size_not_equal_to" }
      let(:error_options_for_file_having_lower_than_equal_to_option) do
        {
          file_size: "1 KB",
          filename: file_having_lower_than_equal_to_option[:filename],
          exact: "5 KB"
        }
      end
      let(:error_options_for_file_having_higher_than_equal_to_option) do
        {
          file_size: "7 KB",
          filename: file_having_higher_than_equal_to_option[:filename],
          exact: "5 KB"
        }
      end

      it_behaves_like "comparison equal_to option"
    end

    describe "zero bounds" do
      context "when equal_to is 0" do
        let(:attribute) { :equal_to_zero }

        context "when provided with a 0-byte file" do
          subject(:record) { model.public_send(attribute).attach(image_file_0ko) and model }

          it { is_expected_to_be_valid }
        end

        context "when provided with a non-empty file" do
          subject(:record) { model.public_send(attribute).attach(file_1ko) and model }

          let(:error_options) do
            {
              file_size: "1 KB",
              filename: file_1ko[:filename],
              exact: "0 Bytes"
            }
          end

          it { is_expected_not_to_be_valid }
          it { is_expected_to_include_error_message("file_size_not_equal_to", with_locales: [ "en" ], error_options: error_options) }
        end
      end

      context "when greater_than_or_equal_to is 0" do
        let(:attribute) { :greater_than_or_equal_to_zero }

        context "when provided with a 0-byte file" do
          subject(:record) { model.public_send(attribute).attach(image_file_0ko) and model }

          it { is_expected_to_be_valid }
        end

        context "when provided with a non-empty file" do
          subject(:record) { model.public_send(attribute).attach(file_1ko) and model }

          it { is_expected_to_be_valid }
        end
      end
    end
  end

  describe "attachments marked for destruction" do
    let(:model) { validator_test_class::Check.new(params) }

    context "when an oversized file is marked for destruction" do
      subject(:record) { model.less_than.attach(file_5ko) and model.less_than.mark_for_destruction and model }

      it { is_expected_to_be_valid }
    end
  end

  describe "Rails options" do
    it_behaves_like "works with all rails common validation options"
  end
end
