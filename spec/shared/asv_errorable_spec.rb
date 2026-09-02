# frozen_string_literal: true

require "rails_helper"

RSpec.describe ActiveStorageValidations::ASVErrorable do
  describe "#initialize_error_options" do
    subject(:error_options) { validator.send(:initialize_error_options, {}, attachable) }

    let(:validator) { ActiveStorageValidations::ContentTypeValidator.new(attributes: :avatar, with: "image/png") }
    let(:png_path) { Rails.root.join("public", "image_150x150.png") }
    let(:expected_filename) { "image_150x150.png" }

    context "when the attachable is an ActionDispatch::Http::UploadedFile" do
      let(:attachable) do
        tempfile = register_fixture_io(Tempfile.new([ "image_150x150", ".png" ]))
        IO.copy_stream(open_fixture(png_path), tempfile)
        tempfile.rewind

        ActionDispatch::Http::UploadedFile.new(
          tempfile: tempfile,
          filename: expected_filename,
          type: "image/png"
        )
      end

      it "includes the original filename" do
        expect(error_options[:filename]).to eq(expected_filename)
      end
    end

    context "when the attachable is a Rack::Test::UploadedFile" do
      let(:attachable) { register_uploaded_file(Rack::Test::UploadedFile.new(png_path, "image/png")) }

      it "includes the original filename" do
        expect(error_options[:filename]).to eq(expected_filename)
      end
    end

    context "when the attachable is a Hash" do
      let(:attachable) do
        {
          io: open_fixture(png_path),
          filename: expected_filename,
          content_type: "image/png"
        }
      end

      it "includes the declared filename" do
        expect(error_options[:filename]).to eq(expected_filename)
      end
    end

    context "when the attachable is a File" do
      let(:attachable) { open_fixture(png_path) }

      it "includes the file basename" do
        expect(error_options[:filename]).to eq(expected_filename)
      end
    end

    context "when the attachable is a Pathname" do
      let(:attachable) { png_path }

      it "includes the file basename" do
        expect(error_options[:filename]).to eq(expected_filename)
      end
    end

    context "when the attachable is an ActiveStorage::Blob" do
      let(:attachable) do
        ActiveStorage::Blob.create_and_upload!(
          io: open_fixture(png_path),
          filename: expected_filename,
          content_type: "image/png"
        )
      end

      it "includes the blob filename" do
        expect(error_options[:filename]).to eq(expected_filename)
      end
    end
  end
end
