# frozen_string_literal: true

require "test_helper"

describe ActiveStorageValidations::ContentTypeSpoofDetector do
  include ValidatorHelpers

  let(:model) { ContentTypeSpoofDetector.new }

  # validates :spoofing_protection, content_type: :jpg
  # validates :spoofing_protection_proc, content_type: -> (record) { :jpg }
  # validates :no_spoofing_protection, content_type: { with: :jpg, spoofing_protection: :none}
  # validates :no_spoofing_protection_proc, content_type: -> (record) { { with: :jpg, spoofing_protection: :none} }
  %w(value proc).each do |value_type|
    describe value_type do
      describe "with spoofing protection activated" do
        let(:attribute) { :"spoofing_protection#{'_proc' if value_type == 'proc'}" }

        describe "when the file is okay" do
          subject { model.public_send(attribute).attach(okay_file) and model }

          let(:okay_file) { jpeg_file }

          it { is_expected_to_be_valid }
        end

        describe "when the file is spoofed (meaning its content does not match filename extension and supplied content_type)" do
          subject { model.public_send(attribute).attach(spoofed_file) and model }

          let(:spoofed_file) { spoofed_jpeg }

          let(:error_options) do
            {
              filename: spoofed_jpeg[:filename]
            }
          end

          it { is_expected_not_to_be_valid }
          it { is_expected_to_have_error_message("spoofed_content_type", error_options: error_options, validator: :content_type) }
          it { is_expected_to_have_error_options(error_options, validator: :content_type) }
        end

        describe "when the file is empty" do
          subject { model.public_send(attribute).attach(empty_file) and model }

          let(:empty_file) { empty_io_file }

          let(:error_options) do
            {
              filename: empty_file[:filename]
            }
          end

          it { is_expected_not_to_be_valid }
          it { is_expected_to_have_error_message("spoofed_content_type", error_options: error_options, validator: :content_type) }
          it { is_expected_to_have_error_options(error_options, validator: :content_type) }
        end

        describe "when the file mime type is not identifiable" do
          subject { model.public_send(attribute).attach(not_identifiable_type) and model }

          let(:not_identifiable_type) { not_identifiable_io_file }

          let(:error_options) do
            {
              filename: not_identifiable_type[:filename]
            }
          end

          it { is_expected_not_to_be_valid }
          it { is_expected_to_have_error_message("spoofed_content_type", error_options: error_options, validator: :content_type) }
          it { is_expected_to_have_error_options(error_options, validator: :content_type) }
        end
      end
    end
  end

  describe "when the file command-line tool is not found" do
    subject { model.public_send(attribute).attach(okay_file) and model }

    let(:okay_file) { jpeg_file }

    let(:attribute) { :spoofing_protection }

    it "raises an explicit error" do
      Open3.stub(:capture2, proc { raise Errno::ENOENT }) do
        error = assert_raises(ActiveStorageValidations::ContentTypeSpoofDetector::FileCommandLineToolNotInstalledError) { subject.valid? }
        assert_equal('file command-line tool is not installed', error.message)
      end
    end
  end

  # validates :many_spoofing_protection, content_type: :jpg
  describe 'with has_many_attached relationship' do
    let(:attribute) { :many_spoofing_protection }

    describe "when the files are okay" do
      subject { model.public_send(attribute).attach(okay_files) and model }

      let(:okay_files) { [okay_jpg_1, okay_jpg_2] }
      let(:okay_jpg_1) { create_blob_from_file(jpeg_file) }
      let(:okay_jpg_2) { create_blob_from_file(jpeg_file) }

      it { is_expected_to_be_valid }
    end

    describe "when one of the file is spoofed" do
      subject { model.public_send(attribute).attach(files) and model }

      let(:files) { [okay_jpg, spoofed_jpeg_file] }
      let(:okay_jpg) { create_blob_from_file(jpeg_file) }
      let(:spoofed_jpeg_file) { create_blob_from_file(spoofed_jpeg) }
      let(:error_options) do
        {
          filename: spoofed_jpeg[:filename]
        }
      end

      it { is_expected_not_to_be_valid }
      it { is_expected_to_have_error_message("spoofed_content_type", error_options: error_options, validator: :content_type) }
      it { is_expected_to_have_error_options(error_options, validator: :content_type) }
    end
  end

  describe "working with most common mime types" do
    most_common_mime_types.each do |common_mime_type|
      describe ".#{common_mime_type[:mime_type]} file" do
        subject { model.public_send(attribute).attach(okay_file) and model }

        let(:media) { common_mime_type[:mime_type].split('/').first }
        let(:content) { common_mime_type[:extension].underscore }
        let(:attribute) { [media, content].join('_') }
        let(:okay_file) do
          {
            io: File.open(Rails.root.join('public', "most_common_mime_types", "example.#{common_mime_type[:extension]}")),
            filename: "example.#{common_mime_type[:extension]}",
            content_type: common_mime_type[:mime_type]
          }
        end

        it "identifies the mime type correctly (ie it is valid, an invalid identification will make it invalid)" do
          is_expected_to_be_valid
        end
      end
    end
  end
end
