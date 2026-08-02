# frozen_string_literal: true

require "open-uri"
require "rails_helper"

RSpec.describe ActiveStorageValidations::Analyzer::ContentTypeAnalyzer do
  let(:analyzer) { described_class.new(attachable) }

  describe "#content_type" do
    def is_expected_to_return_the_right_content_type
      expect(content_type).to eq(expected_content_type)
    end

    def is_expected_to_return_empty_content_type
      expect(content_type).to eq({ content_type: "inode/x-empty" })
    end

    subject(:content_type) { analyzer.content_type }

    describe "returns the right content_type for any attachable" do
      # As stated in ActiveStorage documentation, attachables can either be a:
      #   ActiveStorage::Blob object
      #   ActionDispatch::Http::UploadedFile object
      #   Rack::Test::UploadedFile object
      #   Hash object representing the io / filename / content_type
      #   String object representing the signed reference to blob
      #   File object
      #   Pathname object

      let(:media_extension) { ".png" }
      let(:media_extension_rotated) { ".jpg" }
      let(:media_filename) { "image_150x150#{media_extension}" }
      let(:media_filename_over_10ko) { "image_150x150_28ko#{media_extension}" }
      let(:media_path) { Rails.root.join("public", media_filename) }
      let(:media_io) { File.open(media_path) }
      let(:media_content_type) { "image/png" }
      let(:expected_content_type) { { content_type: "image/png" } }
      let(:expected_content_type_over_10ko) { { content_type: "image/png" } }

      describe "ActiveStorage::Blob object" do
        let(:attachable) do
          ActiveStorage::Blob.create_and_upload!(
            io: media_io,
            filename: media_filename,
            content_type: media_content_type,
            service_name: "test"
          )
        end

        it { is_expected_to_return_the_right_content_type }
      end

      describe "ActionDispatch::Http::UploadedFile object" do
        let(:attachable) do
          tempfile = Tempfile.new([ media_filename, media_extension ])
          tempfile.write(File.read(media_path))
          tempfile.rewind

          ActionDispatch::Http::UploadedFile.new({
            tempfile: tempfile,
            filename: media_filename,
            type: media_content_type
          })
        end

        it { is_expected_to_return_the_right_content_type }
      end

      describe "Rack::Test::UploadedFile object" do
        let(:attachable) { Rack::Test::UploadedFile.new(media_path, media_content_type) }

        it { is_expected_to_return_the_right_content_type }
      end

      describe "Hash object representing the io / filename / content_type" do
        let(:attachable) do
          {
            io: media_io,
            filename: media_filename,
            content_type: media_content_type
          }
        end

        it { is_expected_to_return_the_right_content_type }

        context "when not passed with a content_type" do
          let(:attachable) do
            {
              io: media_io,
              filename: media_filename
            }
          end

          it { is_expected_to_return_the_right_content_type }
        end

        describe "Remote file" do
          before do
            stub_request(:get, url)
              .to_return(body: File.open(Rails.root.join("public", fetched_file)), status: 200)
          end

          let(:url) { "https://example_image.jpg" }
          let(:uri) { URI.parse(url) }
          let(:attachable) do
            {
              io: io,
              filename: fetched_file,
              content_type: media_content_type
            }
          end

          describe "using StringIO constructor as io" do
            let(:io) { StringIO.new(remote_image.to_s) }
            let(:remote_image) { Net::HTTP.get(uri) }
            let(:fetched_file) { media_filename }

            it { is_expected_to_return_the_right_content_type }
          end

          describe "using URI.open constructor as io" do
            let(:io) { uri.open }

            describe "Opening small media (< 10ko) resulting in OpenUri returning a StringIO" do
              let(:fetched_file) { media_filename }

              it { is_expected_to_return_the_right_content_type }
            end

            describe "Opening large media (>= 10ko) resulting in OpenUri returning a Tempfile" do
              let(:fetched_file) { media_filename_over_10ko }
              let(:expected_metadata) { expected_metadata_over_10ko }

              it { is_expected_to_return_the_right_content_type }
            end
          end
        end
      end

      describe "String object representing the signed reference to blob" do
        let(:attachable) do
          blob = ActiveStorage::Blob.create_and_upload!(
            io: media_io,
            filename: media_filename,
            content_type: media_content_type,
            service_name: "test"
          )
          blob.signed_id
        end

        it { is_expected_to_return_the_right_content_type }
      end

      describe "File object" do
        let(:attachable) { media_io }

        if Rails.gem_version >= Gem::Version.new("7.1.0.rc1")
          it { is_expected_to_return_the_right_content_type }
        else
          it { is_expected_to_raise_error(ArgumentError, "Could not find or build blob: expected attachable, got #{attachable.inspect}") }
        end
      end

      describe "Pathname object" do
        let(:attachable) { Pathname.new(media_path) }

        if Rails.gem_version >= Gem::Version.new("7.1.0.rc1")
          it { is_expected_to_return_the_right_content_type }
        else
          it { is_expected_to_raise_error(ArgumentError, "Could not find or build blob: expected attachable, got #{attachable.inspect}") }
        end
      end

      describe "something else" do
        let(:attachable) { 42 }

        it { is_expected_to_raise_error(ArgumentError, "Could not find or build blob: expected attachable, got #{attachable.inspect}") }
      end
    end

    describe "0 byte size file" do
      let(:attachable) do
        ActiveStorage::Blob.create_and_upload!(
          io: File.open(Rails.root.join("public", "image_file_0ko.png")),
          filename: "image_file_0ko.png",
          content_type: "image/png",
          service_name: "test"
        )
      end

      it { is_expected_to_return_empty_content_type }
    end

    context "when the file command-line tool is not found" do
      let(:attachable) do
        {
          io: File.open(Rails.root.join("public", "image_150x150.png")),
          filename: "image_150x150.png",
          content_type: "image/png"
        }
      end
      let(:analyzer_error) { described_class::FileCommandLineToolNotInstalledError }

      it "raises an explicit error" do
        allow(Process).to receive(:spawn).and_raise(Errno::ENOENT)
        expect { content_type }.to raise_error(analyzer_error, "file command-line tool is not installed")
      end
    end
  end

  describe "timeouts" do
    let(:path) { Rails.root.join("public", "image_150x150.png").to_s }
    let(:attachable) do
      {
        io: File.open(path),
        filename: "image_150x150.png",
        content_type: "image/png"
      }
    end
    let(:analyzer) { described_class.new(attachable, timeout: 5.seconds) }

    after { ActiveStorageValidations.command_timeout = 10.seconds }

    context "when the command times out" do
      subject(:media) { analyzer.send(:media_from_path, path) }

      before { allow(analyzer).to receive(:run_command).and_return(timed_out_command_result) }

      it "returns nil from media_from_path" do
        expect(media).to be_nil
      end
    end

    context "when analyze.active_storage_validations is instrumented" do
      it "includes timeout metadata" do
        payloads = []
        subscriber = ActiveSupport::Notifications.subscribe("analyze.active_storage_validations") do |*args|
          payloads << ActiveSupport::Notifications::Event.new(*args).payload
        end

        analyzer.content_type

        payload = payloads.find { |entry| entry[:analyzer] == "file" }
        expect(payload).to be_truthy
        expect(payload[:timeout]).to eq(5.0)
        expect(payload[:timed_out]).to be(false)
        expect(payload).to have_key(:duration)
        expect(payload[:duration]).to be >= 0
      ensure
        ActiveSupport::Notifications.unsubscribe(subscriber)
      end
    end
  end
end
