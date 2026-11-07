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

    context "with the validator options" do
      subject(:error_options) { validator.send(:initialize_error_options, validator.options, nil) }

      let(:validator) do
        ActiveStorageValidations::SizeValidator.new(
          attributes: :avatar,
          less_than: ->(_record) { 10.megabytes },
          timeout: 2.seconds,
          message: "too big",
          if: :persisted?,
          on: :create
        )
      end

      it "leaves the check options out, like Rails validators do" do
        expect(error_options).not_to have_key(:less_than)
      end

      it "leaves the gem configuration options out" do
        expect(error_options).not_to have_key(:timeout)
      end

      it "forwards the Rails options" do
        expect(error_options).to include(message: "too big", if: :persisted?, on: :create)
      end

      it "adds the gem error options" do
        expect(error_options).to include(validator_type: :size, custom_message: "too big")
      end
    end

    context "with a content_type validator" do
      subject(:error_options) { validator.send(:initialize_error_options, validator.options, nil) }

      let(:validator) do
        ActiveStorageValidations::ContentTypeValidator.new(
          attributes: :avatar,
          in: [ "image/png" ],
          spoofing_protection: true,
          timeout: 2.seconds
        )
      end

      it "leaves the content types and the spoofing configuration out" do
        expect(error_options.keys).to contain_exactly(:validator_type)
      end
    end
  end

  describe "errors.details" do
    subject(:details) { record.errors.details[:less_than_proc] }

    let(:record) { Size::Validator::Check.new }

    before do
      record.less_than_proc.attach(file_5ko)
      record.valid?
    end

    it "only exposes the documented, resolved values" do
      expect(details).to contain_exactly(
        a_hash_including(error: :file_size_not_less_than, validator_type: :size, max: "2 KB", file_size: "5 KB", filename: file_5ko[:filename])
      )
    end

    it "does not leak the Proc option" do
      expect(details.first).not_to have_key(:less_than)
    end

    it "stays JSON serializable" do
      expect(JSON.parse(details.to_json).first).to include("error" => "file_size_not_less_than", "max" => "2 KB")
    end
  end
end
