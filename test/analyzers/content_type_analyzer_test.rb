# frozen_string_literal: true

require "open-uri"
require "test_helper"
require 'analyzers/support/analyzer_helpers'

describe ActiveStorageValidations::Analyzer::ContentTypeAnalyzer do
  include AnalyzerHelpers

  let(:analyzer_klass) { ActiveStorageValidations::Analyzer::ContentTypeAnalyzer }
  let(:analyzer) { analyzer_klass.new(attachable) }

  describe "#content_type" do
    def is_expected_to_return_the_right_content_type
      assert_equal(expected_content_type, subject)
    end

    def is_expected_to_return_empty_content_type
      assert_equal("inode/x-empty", subject)
    end

    subject { analyzer.content_type }

    describe "returns the right content_type for any attachable" do
      # As stated in ActiveStorage documentation, attachables can either be a:
      #   ActiveStorage::Blob object
      #   ActionDispatch::Http::UploadedFile object
      #   Rack::Test::UploadedFile object
      #   Hash object representing the io / filename / content_type
      #   String object representing the signed reference to blob
      #   File object
      #   Pathname object

      let(:media_extension) { '.png' }
      let(:media_extension_rotated) { '.jpg' }
      let(:media_filename) { "image_150x150#{media_extension}" }
      let(:media_filename_over_10ko) { "image_150x150_28ko#{media_extension}" }
      let(:media_path) { Rails.root.join('public', media_filename) }
      let(:media_io) { File.open(media_path) }
      let(:media_content_type) { 'image/png' }
      let(:expected_content_type) { 'image/png' }
      let(:expected_content_type_over_10ko) { 'image/png' }

      describe "ActiveStorage::Blob object" do
        let(:attachable) do
          ActiveStorage::Blob.create_and_upload!(
            io: media_io,
            filename: media_filename,
            content_type: media_content_type,
            service_name: 'test'
          )
        end

        it { is_expected_to_return_the_right_content_type }
      end

      describe "ActionDispatch::Http::UploadedFile object" do
        let(:attachable) do
          tempfile = Tempfile.new([media_filename, media_extension])
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

        describe "when not passed with a content_type" do
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
              .to_return(body: File.open(Rails.root.join('public', fetched_file)), status: 200)
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
            service_name: 'test'
          )
          blob.signed_id
        end

        it { is_expected_to_return_the_right_content_type }
      end

      describe "File object" do
        let(:attachable) { media_io }

        if Rails.gem_version >= Gem::Version.new('7.1.0.rc1')
          it { is_expected_to_return_the_right_content_type }
        else
          it { is_expected_to_raise_error(ArgumentError, "Could not find or build blob: expected attachable, got #{attachable.inspect}") }
        end
      end

      describe "Pathname object" do
        let(:attachable) { Pathname.new(media_path) }

        if Rails.gem_version >= Gem::Version.new('7.1.0.rc1')
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
          io: File.open(Rails.root.join('public', "image_file_0ko.png")),
          filename: "image_file_0ko.png",
          content_type: 'image/png',
          service_name: 'test'
        )
      end

      it { is_expected_to_return_empty_content_type }
    end

    describe "when the file command-line tool is not found" do
      let(:attachable) do
        {
          io: File.open(Rails.root.join('public', "image_150x150.png")),
          filename: "image_150x150.png",
          content_type: "image/png"
        }
      end
      let(:analyzer_error) { analyzer_klass::FileCommandLineToolNotInstalledError }

      it "raises an explicit error" do
        Open3.stub(:capture2, proc { raise Errno::ENOENT }) do
          error = assert_raises(analyzer_error) { subject }
          assert_equal('file command-line tool is not installed', error.message)
        end
      end
    end
  end
end
