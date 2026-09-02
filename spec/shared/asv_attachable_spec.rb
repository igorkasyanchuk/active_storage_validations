# frozen_string_literal: true

require "rails_helper"

RSpec.describe ActiveStorageValidations::ASVAttachable do
  let(:validator) { ActiveStorageValidations::ContentTypeValidator.new(attributes: :avatar, with: "image/png") }
  let(:png_path) { Rails.root.join("public", "image_150x150.png") }
  let(:png_filename) { "image_150x150.png" }
  let(:png_bytes) { File.binread(png_path) }
  let(:blob) do
    ActiveStorage::Blob.create_and_upload!(
      io: open_fixture(png_path),
      filename: png_filename,
      content_type: "image/png"
    )
  end

  def uploaded_file
    tempfile = register_fixture_io(Tempfile.new([ "image_150x150", ".png" ]))
    IO.copy_stream(open_fixture(png_path), tempfile)
    tempfile.rewind

    ActionDispatch::Http::UploadedFile.new(
      tempfile: tempfile,
      filename: png_filename,
      type: "image/png"
    )
  end

  def hash_attachable
    {
      io: open_fixture(png_path, "rb"),
      filename: png_filename,
      content_type: "image/png"
    }
  end

  def close_io(io)
    io.close unless io.closed?
  end

  file_attachments_supported = Rails.gem_version >= Gem::Version.new("7.1.0.rc1")

  shared_examples "rejects an unknown attachable" do
    describe "something else" do
      let(:attachable) { 42 }

      it "raises ArgumentError" do
        expect { result }.to raise_error(ArgumentError, /Could not find or build blob/)
      end
    end
  end

  shared_examples "rejects File and Pathname when unsupported" do
    context "when File attachments are not supported" do
      before do
        allow(validator).to receive_messages(
          supports_file_attachment?: false,
          supports_pathname_attachment?: false
        )
      end

      describe "File object" do
        let(:attachable) { open_fixture(png_path, "rb") }

        after { close_io(attachable) }

        it "raises ArgumentError" do
          expect { result }.to raise_error(ArgumentError, /Could not find or build blob/)
        end
      end

      describe "Pathname object" do
        let(:attachable) { Pathname.new(png_path) }

        it "raises ArgumentError" do
          expect { result }.to raise_error(ArgumentError, /Could not find or build blob/)
        end
      end
    end
  end

  describe "#attachable_content_type_rails_like" do
    subject(:result) { validator.send(:attachable_content_type_rails_like, attachable) }

    shared_examples "detects a png content type" do
      it "returns the Marcel content type" do
        expect(result).to eq("image/png")
      end
    end

    describe "ActiveStorage::Blob object" do
      let(:attachable) { blob }

      it_behaves_like "detects a png content type"
    end

    describe "ActionDispatch::Http::UploadedFile object" do
      let(:attachable) { uploaded_file }

      it_behaves_like "detects a png content type"
    end

    describe "Rack::Test::UploadedFile object" do
      let(:attachable) { register_uploaded_file(Rack::Test::UploadedFile.new(png_path, "image/png")) }

      it_behaves_like "detects a png content type"
    end

    describe "String object representing the signed reference to blob" do
      let(:attachable) { blob.signed_id }

      it_behaves_like "detects a png content type"
    end

    describe "Hash object representing the io / filename / content_type" do
      let(:attachable) { hash_attachable }

      after { close_io(attachable[:io]) }

      it_behaves_like "detects a png content type"
    end

    describe "File object" do
      let(:attachable) { open_fixture(png_path, "rb") }

      after { close_io(attachable) }

      if file_attachments_supported
        it_behaves_like "detects a png content type"
      else
        it "raises ArgumentError" do
          expect { result }.to raise_error(ArgumentError, /Could not find or build blob/)
        end
      end
    end

    describe "Pathname object" do
      let(:attachable) { Pathname.new(png_path) }

      if file_attachments_supported
        it_behaves_like "detects a png content type"
      else
        it "raises ArgumentError" do
          expect { result }.to raise_error(ArgumentError, /Could not find or build blob/)
        end
      end
    end

    it_behaves_like "rejects an unknown attachable"
    it_behaves_like "rejects File and Pathname when unsupported"
  end

  describe "#full_attachable_content_type" do
    subject(:result) { validator.send(:full_attachable_content_type, attachable) }

    shared_examples "returns the png content type" do
      it "returns the declared content type" do
        expect(result).to eq("image/png")
      end
    end

    describe "ActiveStorage::Blob object" do
      let(:attachable) { blob }

      it_behaves_like "returns the png content type"
    end

    describe "ActionDispatch::Http::UploadedFile object" do
      let(:attachable) { uploaded_file }

      it_behaves_like "returns the png content type"
    end

    describe "Rack::Test::UploadedFile object" do
      let(:attachable) { register_uploaded_file(Rack::Test::UploadedFile.new(png_path, "image/png")) }

      it_behaves_like "returns the png content type"
    end

    describe "String object representing the signed reference to blob" do
      let(:attachable) { blob.signed_id }

      it_behaves_like "returns the png content type"
    end

    describe "Hash object representing the io / filename / content_type" do
      let(:attachable) { hash_attachable }

      after { close_io(attachable[:io]) }

      it_behaves_like "returns the png content type"
    end

    describe "File object" do
      let(:attachable) { open_fixture(png_path, "rb") }

      after { close_io(attachable) }

      if file_attachments_supported
        it_behaves_like "returns the png content type"
      else
        it "raises ArgumentError" do
          expect { result }.to raise_error(ArgumentError, /Could not find or build blob/)
        end
      end
    end

    describe "Pathname object" do
      let(:attachable) { Pathname.new(png_path) }

      if file_attachments_supported
        it_behaves_like "returns the png content type"
      else
        it "raises ArgumentError" do
          expect { result }.to raise_error(ArgumentError, /Could not find or build blob/)
        end
      end
    end

    it_behaves_like "rejects an unknown attachable"
    it_behaves_like "rejects File and Pathname when unsupported"
  end

  describe "#attachable_content_type" do
    subject(:result) { validator.send(:attachable_content_type, attachable) }

    shared_examples "returns the png content type without parameters" do
      it "returns the declared content type" do
        expect(result).to eq("image/png")
      end
    end

    describe "ActiveStorage::Blob object" do
      let(:attachable) { blob }

      it_behaves_like "returns the png content type without parameters"
    end

    describe "ActionDispatch::Http::UploadedFile object" do
      let(:attachable) { uploaded_file }

      it_behaves_like "returns the png content type without parameters"
    end

    describe "Rack::Test::UploadedFile object" do
      let(:attachable) { register_uploaded_file(Rack::Test::UploadedFile.new(png_path, "image/png")) }

      it_behaves_like "returns the png content type without parameters"
    end

    describe "String object representing the signed reference to blob" do
      let(:attachable) { blob.signed_id }

      it_behaves_like "returns the png content type without parameters"
    end

    describe "Hash object representing the io / filename / content_type" do
      let(:attachable) { hash_attachable }

      after { close_io(attachable[:io]) }

      it_behaves_like "returns the png content type without parameters"

      context "when the declared content type has mime parameters" do
        let(:attachable) { hash_attachable.merge(content_type: "application/x-rar-compressed;version=5") }

        it "strips the parameters" do
          expect(result).to eq("application/x-rar-compressed")
        end
      end

      context "when the declared content type is blank" do
        let(:attachable) { hash_attachable.merge(content_type: nil) }

        it "falls back to the Marcel type from the filename" do
          expect(result).to eq("image/png")
        end
      end
    end

    describe "File object" do
      let(:attachable) { open_fixture(png_path, "rb") }

      after { close_io(attachable) }

      if file_attachments_supported
        it_behaves_like "returns the png content type without parameters"
      else
        it "raises ArgumentError" do
          expect { result }.to raise_error(ArgumentError, /Could not find or build blob/)
        end
      end
    end

    describe "Pathname object" do
      let(:attachable) { Pathname.new(png_path) }

      if file_attachments_supported
        it_behaves_like "returns the png content type without parameters"
      else
        it "raises ArgumentError" do
          expect { result }.to raise_error(ArgumentError, /Could not find or build blob/)
        end
      end
    end

    it_behaves_like "rejects an unknown attachable"
    it_behaves_like "rejects File and Pathname when unsupported"
  end

  describe "#attachable_media_type" do
    subject(:result) { validator.send(:attachable_media_type, attachable) }

    shared_examples "returns the image media type" do
      it "returns the media type" do
        expect(result).to eq("image")
      end
    end

    describe "ActiveStorage::Blob object" do
      let(:attachable) { blob }

      it_behaves_like "returns the image media type"
    end

    describe "ActionDispatch::Http::UploadedFile object" do
      let(:attachable) { uploaded_file }

      it_behaves_like "returns the image media type"
    end

    describe "Rack::Test::UploadedFile object" do
      let(:attachable) { register_uploaded_file(Rack::Test::UploadedFile.new(png_path, "image/png")) }

      it_behaves_like "returns the image media type"
    end

    describe "String object representing the signed reference to blob" do
      let(:attachable) { blob.signed_id }

      it_behaves_like "returns the image media type"
    end

    describe "Hash object representing the io / filename / content_type" do
      let(:attachable) { hash_attachable }

      after { close_io(attachable[:io]) }

      it_behaves_like "returns the image media type"

      context "when the declared content type is blank" do
        let(:attachable) { hash_attachable.merge(content_type: nil) }

        it "falls back to the Marcel type from the filename" do
          expect(result).to eq("image")
        end
      end
    end

    describe "File object" do
      let(:attachable) { open_fixture(png_path, "rb") }

      after { close_io(attachable) }

      if file_attachments_supported
        it_behaves_like "returns the image media type"
      else
        it "raises ArgumentError" do
          expect { result }.to raise_error(ArgumentError, /Could not find or build blob/)
        end
      end
    end

    describe "Pathname object" do
      let(:attachable) { Pathname.new(png_path) }

      if file_attachments_supported
        it_behaves_like "returns the image media type"
      else
        it "raises ArgumentError" do
          expect { result }.to raise_error(ArgumentError, /Could not find or build blob/)
        end
      end
    end

    it_behaves_like "rejects an unknown attachable"
    it_behaves_like "rejects File and Pathname when unsupported"
  end

  describe "#content_type_without_parameters" do
    subject(:result) { validator.send(:content_type_without_parameters, content_type) }

    context "when the content type is nil" do
      let(:content_type) { nil }

      it "returns nil" do
        expect(result).to be_nil
      end
    end

    context "when the content type has no parameters" do
      let(:content_type) { "image/png" }

      it "returns the content type" do
        expect(result).to eq("image/png")
      end
    end

    context "when the content type is mixed case" do
      let(:content_type) { "IMAGE/PNG" }

      it "downcases the content type" do
        expect(result).to eq("image/png")
      end
    end

    context "when the content type has a semicolon parameter" do
      let(:content_type) { "application/x-rar-compressed;version=5" }

      it "strips the parameter" do
        expect(result).to eq("application/x-rar-compressed")
      end
    end

    context "when the content type has a comma" do
      let(:content_type) { "image/png, application/octet-stream" }

      it "keeps the first type" do
        expect(result).to eq("image/png")
      end
    end

    context "when the content type has trailing whitespace" do
      let(:content_type) { "image/png charset=utf-8" }

      it "strips from the first whitespace" do
        expect(result).to eq("image/png")
      end
    end
  end

  describe "#attachable_filename" do
    subject(:result) { validator.send(:attachable_filename, attachable) }

    shared_examples "returns the png filename" do
      it "returns the declared filename" do
        expect(result.to_s).to eq(png_filename)
      end
    end

    describe "ActiveStorage::Blob object" do
      let(:attachable) { blob }

      it_behaves_like "returns the png filename"
    end

    describe "ActionDispatch::Http::UploadedFile object" do
      let(:attachable) { uploaded_file }

      it_behaves_like "returns the png filename"
    end

    describe "Rack::Test::UploadedFile object" do
      let(:attachable) { register_uploaded_file(Rack::Test::UploadedFile.new(png_path, "image/png")) }

      it_behaves_like "returns the png filename"
    end

    describe "String object representing the signed reference to blob" do
      let(:attachable) { blob.signed_id }

      it_behaves_like "returns the png filename"
    end

    describe "Hash object representing the io / filename / content_type" do
      let(:attachable) { hash_attachable }

      after { close_io(attachable[:io]) }

      it_behaves_like "returns the png filename"
    end

    describe "File object" do
      let(:attachable) { open_fixture(png_path, "rb") }

      after { close_io(attachable) }

      if file_attachments_supported
        it_behaves_like "returns the png filename"
      else
        it "raises ArgumentError" do
          expect { result }.to raise_error(ArgumentError, /Could not find or build blob/)
        end
      end
    end

    describe "Pathname object" do
      let(:attachable) { Pathname.new(png_path) }

      if file_attachments_supported
        it_behaves_like "returns the png filename"
      else
        it "raises ArgumentError" do
          expect { result }.to raise_error(ArgumentError, /Could not find or build blob/)
        end
      end
    end

    it_behaves_like "rejects an unknown attachable"
    it_behaves_like "rejects File and Pathname when unsupported"
  end

  describe "#attachable_io" do
    subject(:result) { validator.send(:attachable_io, attachable) }

    shared_examples "reads the png bytes" do |rewindable: false|
      it "returns the file bytes" do
        expect(result.b).to eq(png_bytes.b)
      end

      if rewindable
        it "rewinds the io" do
          validator.send(:attachable_io, attachable)
          readable = attachable.is_a?(Hash) ? attachable[:io] : attachable
          expect(readable.read.b).to eq(png_bytes.b)
        end
      end

      context "with a max_byte_size" do
        subject(:result) { validator.send(:attachable_io, attachable, max_byte_size: 8) }

        it "returns the first bytes" do
          expect(result.b).to eq(png_bytes.byteslice(0, 8).b)
        end
      end
    end

    describe "ActiveStorage::Blob object" do
      let(:attachable) { blob }

      it_behaves_like "reads the png bytes"
    end

    describe "ActionDispatch::Http::UploadedFile object" do
      let(:attachable) { uploaded_file }

      it_behaves_like "reads the png bytes", rewindable: true
    end

    describe "Rack::Test::UploadedFile object" do
      let(:attachable) { register_uploaded_file(Rack::Test::UploadedFile.new(png_path, "image/png")) }

      it_behaves_like "reads the png bytes", rewindable: true
    end

    describe "String object representing the signed reference to blob" do
      let(:attachable) { blob.signed_id }

      it_behaves_like "reads the png bytes"
    end

    describe "Hash object representing the io / filename / content_type" do
      let(:attachable) { hash_attachable }

      after { close_io(attachable[:io]) }

      it_behaves_like "reads the png bytes", rewindable: true
    end

    describe "File object" do
      let(:attachable) { open_fixture(png_path, "rb") }

      after { close_io(attachable) }

      if file_attachments_supported
        it_behaves_like "reads the png bytes", rewindable: true
      else
        it "raises ArgumentError" do
          expect { result }.to raise_error(ArgumentError, /Could not find or build blob/)
        end
      end
    end

    describe "Pathname object" do
      let(:attachable) { Pathname.new(png_path) }

      if file_attachments_supported
        it_behaves_like "reads the png bytes"
      else
        it "raises ArgumentError" do
          expect { result }.to raise_error(ArgumentError, /Could not find or build blob/)
        end
      end
    end

    it_behaves_like "rejects an unknown attachable"
    it_behaves_like "rejects File and Pathname when unsupported"
  end

  describe "#rewind_attachable_io" do
    subject(:result) { validator.send(:rewind_attachable_io, attachable) }

    shared_examples "does not raise" do
      it "does not raise" do
        expect { result }.not_to raise_error
      end
    end

    shared_examples "rewinds the readable io" do
      let(:readable) { attachable.is_a?(Hash) ? attachable[:io] : attachable }

      before { readable.read }

      it "rewinds so the io can be read again" do
        result
        expect(readable.read.b).to eq(png_bytes.b)
      end
    end

    describe "ActiveStorage::Blob object" do
      let(:attachable) { blob }

      it_behaves_like "does not raise"
    end

    describe "ActionDispatch::Http::UploadedFile object" do
      let(:attachable) { uploaded_file }

      it_behaves_like "rewinds the readable io"
    end

    describe "Rack::Test::UploadedFile object" do
      let(:attachable) { register_uploaded_file(Rack::Test::UploadedFile.new(png_path, "image/png")) }

      it_behaves_like "rewinds the readable io"
    end

    describe "String object representing the signed reference to blob" do
      let(:attachable) { blob.signed_id }

      it_behaves_like "does not raise"
    end

    describe "Hash object representing the io / filename / content_type" do
      let(:attachable) { hash_attachable }

      after { close_io(attachable[:io]) }

      it_behaves_like "rewinds the readable io"
    end

    describe "File object" do
      let(:attachable) { open_fixture(png_path, "rb") }

      after { close_io(attachable) }

      if file_attachments_supported
        it_behaves_like "rewinds the readable io"
      else
        it "raises ArgumentError" do
          expect { result }.to raise_error(ArgumentError, /Could not find or build blob/)
        end
      end
    end

    describe "Pathname object" do
      let(:attachable) { Pathname.new(png_path) }

      if file_attachments_supported
        it_behaves_like "does not raise"
      else
        it "raises ArgumentError" do
          expect { result }.to raise_error(ArgumentError, /Could not find or build blob/)
        end
      end
    end

    it_behaves_like "rejects an unknown attachable"
    it_behaves_like "rejects File and Pathname when unsupported"
  end
end
