# frozen_string_literal: true

require "open-uri"

module ReturnsTheRightMetadataForAnyAttachable
  extend ActiveSupport::Concern

  included do
    describe "#metadata" do
      def is_expected_to_return_the_right_metadata
        assert_equal(expected_metadata, subject)
      end

      def is_expected_to_return_empty_metadata
        assert_equal({}, subject)
      end

      subject { analyzer.metadata }

      describe "returns the right metadata for any attachable" do
        # As stated in ActiveStorage documentation, attachables can either be a:
        #   ActiveStorage::Blob object
        #   ActionDispatch::Http::UploadedFile object
        #   Rack::Test::UploadedFile object
        #   Hash object representing the io / filename / content_type
        #   String object representing the signed reference to blob
        #   File object
        #   Pathname object

        describe "ActiveStorage::Blob object" do
          let(:attachable) do
            ActiveStorage::Blob.create_and_upload!(
              io: media_io,
              filename: media_filename,
              content_type: media_content_type,
              service_name: 'test'
            )
          end

          it { is_expected_to_return_the_right_metadata }
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

          it { is_expected_to_return_the_right_metadata }
        end

        describe "Rack::Test::UploadedFile object" do
          let(:attachable) { Rack::Test::UploadedFile.new(media_path, media_content_type) }

          it { is_expected_to_return_the_right_metadata }
        end

        describe "Hash object representing the io / filename / content_type" do
          let(:attachable) do
            {
              io: media_io,
              filename: media_filename,
              content_type: media_content_type
            }
          end

          it { is_expected_to_return_the_right_metadata }

          describe "when not passed with a content_type" do
            let(:attachable) do
              {
                io: media_io,
                filename: media_filename
              }
            end

            it { is_expected_to_return_the_right_metadata }
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

              it { is_expected_to_return_the_right_metadata }
            end

            describe "using URI.open constructor as io" do
              let(:io) { uri.open }

              describe "Opening small media (< 10ko) resulting in OpenUri returning a StringIO" do
                let(:fetched_file) { media_filename }

                it { is_expected_to_return_the_right_metadata }
              end

              describe "Opening large media (>= 10ko) resulting in OpenUri returning a Tempfile" do
                let(:fetched_file) { media_filename_over_10ko }
                let(:expected_metadata) { expected_metadata_over_10ko }

                it { is_expected_to_return_the_right_metadata }
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

          it { is_expected_to_return_the_right_metadata }
        end

        describe "File object" do
          let(:attachable) { media_io }

          if Rails.gem_version >= Gem::Version.new('7.1.0.rc1')
            it { is_expected_to_return_the_right_metadata }
          else
            it { is_expected_to_raise_error(ArgumentError, "Could not find or build blob: expected attachable, got #{attachable.inspect}") }
          end
        end

        describe "Pathname object" do
          let(:attachable) { Pathname.new(media_path) }

          if Rails.gem_version >= Gem::Version.new('7.1.0.rc1')
            it { is_expected_to_return_the_right_metadata }
          else
            it { is_expected_to_raise_error(ArgumentError, "Could not find or build blob: expected attachable, got #{attachable.inspect}") }
          end
        end

        describe "something else" do
          let(:attachable) { 42 }

          it { is_expected_to_raise_error(ArgumentError, "Could not find or build blob: expected attachable, got #{attachable.inspect}") }
        end
      end

      describe "Edge cases" do
        describe "rotated media" do
          let(:attachable) do
            ActiveStorage::Blob.create_and_upload!(
              io: File.open(Rails.root.join('public', media_filename_rotated)),
              filename: media_filename_rotated,
              content_type: media_content_type_rotated,
              service_name: 'test'
            )
          end
          let(:expected_metadata) { expected_metadata_rotated }

          it { is_expected_to_return_the_right_metadata }
        end

        describe "0 byte size file" do
          let(:attachable) do
            ActiveStorage::Blob.create_and_upload!(
              io: File.open(Rails.root.join('public', media_filename_0ko)),
              filename: media_filename_0ko,
              content_type: media_content_type,
              service_name: 'test'
            )
          end

          it { is_expected_to_return_empty_metadata }
        end
      end
    end
  end
end
