# frozen_string_literal: true

require "rails_helper"

# The notification payloads named the command, not the file: a slow or timed
# out analysis could not be traced back to its upload.
RSpec.describe ActiveStorageValidations::Analyzer do
  subject(:payload) do
    payloads = []
    subscriber = ActiveSupport::Notifications.subscribe(event) { |*, event_payload| payloads << event_payload }
    analyzer.content_type
    payloads.last
  ensure
    ActiveSupport::Notifications.unsubscribe(subscriber)
  end

  let(:analyzer) { ActiveStorageValidations::Analyzer::ContentTypeAnalyzer::File.new(attachable) }
  let(:event) { "analyze.active_storage_validations" }
  let(:path) { Rails.root.join("public", "image_150x150.png") }
  let(:file_payload) { { filename: "image_150x150.png", content_type: "image/png", byte_size: File.size(path), blob_key: nil } }

  describe "analyze.active_storage_validations" do
    context "with an ActiveStorage::Blob" do
      let(:attachable) do
        ActiveStorage::Blob.create_and_upload!(io: open_fixture(path), filename: "image_150x150.png", content_type: "image/png")
      end

      it { expect(payload).to include(file_payload.merge(blob_key: attachable.key)) }
    end

    context "with a signed blob id" do
      let(:blob) do
        ActiveStorage::Blob.create_and_upload!(io: open_fixture(path), filename: "image_150x150.png", content_type: "image/png")
      end
      let(:attachable) { blob.signed_id }

      it { expect(payload).to include(file_payload.merge(blob_key: blob.key)) }
    end

    context "with a Hash io" do
      let(:attachable) { { io: StringIO.new(File.binread(path)), filename: "image_150x150.png", content_type: "image/png" } }

      it { expect(payload).to include(file_payload) }
    end

    context "with an uploaded file" do
      let(:attachable) { register_uploaded_file(Rack::Test::UploadedFile.new(path, "image/png")) }

      it { expect(payload).to include(file_payload) }
    end

    # File and Pathname attachables need Rails 7.1.
    if Rails.gem_version >= Gem::Version.new("7.1.0.rc1")
      context "with a File" do
        let(:attachable) { open_fixture(path, "rb") }

        it { expect(payload).to include(file_payload) }
      end

      context "with a Pathname" do
        let(:attachable) { path }

        it { expect(payload).to include(file_payload) }
      end
    end

    context "with an io that does not know its size" do
      let(:io) { Class.new(StringIO) { undef_method :size }.new(File.binread(path)) }
      let(:attachable) { { io: io, filename: "image_150x150.png", content_type: "image/png" } }

      it { expect(payload).to include(file_payload.merge(byte_size: nil)) }
    end
  end

  describe "timeout.active_storage_validations" do
    let(:event) { "timeout.active_storage_validations" }
    let(:analyzer) { ActiveStorageValidations::Analyzer::ContentTypeAnalyzer::File.new(attachable, timeout: 0.2) }
    let(:attachable) { { io: StringIO.new(File.binread(path)), filename: "image_150x150.png", content_type: "image/png" } }

    before do
      allow(analyzer).to receive(:run_command).and_wrap_original do |_original, *, payload:|
        analyzer.send(:mark_timed_out!, payload, "file")
        ActiveStorageValidations::ASVCommandable::CommandResult.new(stdout: "", stderr: "", status: nil, timed_out: true)
      end
    end

    it { expect(payload).to include(file_payload.merge(analyzer: "file", command: "file", timeout: 0.2)) }
  end
end
