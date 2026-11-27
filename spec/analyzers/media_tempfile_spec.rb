# frozen_string_literal: true

require "rails_helper"

RSpec.describe ActiveStorageValidations::Analyzer::MediaTempfile do
  subject(:tempfile) { described_class.new([ "ActiveStorageValidations-", ".png" ]) }

  def files_named_like_media_tempfiles
    Dir[File.join(Dir.tmpdir, "ActiveStorageValidations-*")]
  end

  describe "before #to_io" do
    it { is_expected.not_to be_created }

    it "creates no file" do
      expect { tempfile }.not_to(change { files_named_like_media_tempfiles })
    end

    it "has nothing to close or delete" do
      expect { tempfile.close and tempfile.delete }.not_to raise_error
    end
  end

  describe "#to_io" do
    subject(:file) { tempfile.to_io }

    after { tempfile.delete }

    it { is_expected.to be_a(File) }
    it { expect(file.path).to start_with(File.join(Dir.tmpdir, "ActiveStorageValidations-")).and end_with(".png") }
    it { expect(file).to be_binmode }
    it { expect(File.stat(file.path).mode & 0o777).to eq(0o600) }

    it "returns the same file every time" do
      expect(tempfile.to_io).to equal(file)
    end

    it "marks the tempfile created" do
      file
      expect(tempfile).to be_created
    end

    # ASVAttachableAdapter#copy_to_tempfile: copy, flush, rewind, read the path.
    it "holds what is copied to it" do
      IO.copy_stream(StringIO.new("\x89PNG\r\n".b * 1000), file)
      file.flush
      file.rewind

      expect(File.binread(file.path)).to eq("\x89PNG\r\n".b * 1000)
    end
  end

  describe "#close" do
    before { tempfile.to_io }

    after { tempfile.delete }

    it "closes the file and keeps it on disk" do
      tempfile.close

      expect(tempfile.to_io).to be_closed
      expect(File).to exist(tempfile.to_io.path)
    end

    it "can be called twice" do
      tempfile.close
      expect { tempfile.close }.not_to raise_error
    end
  end

  describe "#delete" do
    let!(:path) { tempfile.to_io.path }

    it "closes and removes the file" do
      tempfile.delete

      expect(tempfile.to_io).to be_closed
      expect(File).not_to exist(path)
    end

    it "removes a file the analyzer already closed" do
      tempfile.close
      tempfile.delete

      expect(File).not_to exist(path)
    end

    it "ignores a file removed by someone else, and a second call" do
      File.unlink(path)

      expect { tempfile.delete and tempfile.delete }.not_to raise_error
    end
  end
end
