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

        let(:png_image) { Rails.root.join('public', 'image_150x150.png') }
        let(:expected_metadata) { { width: 150, height: 150 } }

        describe "persisted ActiveStorage::Blob object" do
          let(:attachable) do
            ActiveStorage::Blob.create_and_upload!(
              io: File.open(png_image),
              filename: 'image_150x150.png',
              content_type: 'image/png',
              service_name: 'test'
            )
          end

          it { is_expected_to_return_the_right_metadata }
        end

        describe "non-persisted ActiveStorage::Blob object" do
          let(:attachable) do
            ActiveStorage::Blob.new(
              io: File.open(png_image),
              filename: 'image_150x150.png',
              content_type: 'image/png',
              service_name: 'test'
            )
          end
        end

        describe "ActionDispatch::Http::UploadedFile object" do
          let(:attachable) do
            tempfile = Tempfile.new(['image_150x150', '.png'])
            tempfile.write(File.read(png_image))
            tempfile.rewind

            ActionDispatch::Http::UploadedFile.new({
              tempfile: tempfile,
              filename: 'image_150x150.png',
              type: 'image/png'
            })
          end

          it { is_expected_to_return_the_right_metadata }
        end

        describe "Rack::Test::UploadedFile object" do
          let(:attachable) { Rack::Test::UploadedFile.new(png_image, 'image/png') }

          it { is_expected_to_return_the_right_metadata }
        end

        describe "Hash object representing the io / filename / content_type" do
          let(:attachable) do
            {
              io: File.open(png_image),
              filename: 'image_150x150.png',
              content_type: 'image/png'
            }
          end

          it { is_expected_to_return_the_right_metadata }

          describe "when not passed with a content_type" do
            let(:attachable) do
              {
                io: File.open(png_image),
                filename: 'image_150x150.png'
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
                content_type: 'image/png'
              }
            end

            describe "using StringIO constructor as io" do
              let(:io) { StringIO.new(remote_image.to_s) }
              let(:remote_image) { Net::HTTP.get(uri) }
              let(:fetched_file) { 'image_150x150.png' }

              it { is_expected_to_return_the_right_metadata }
            end

            describe "using URI.open constructor as io" do
              let(:io) { uri.open }

              describe "Opening small images (< 10ko) resulting in OpenUri returning a StringIO" do
                let(:fetched_file) { 'image_150x150.png' }

                it { is_expected_to_return_the_right_metadata }
              end

              describe "Opening large images (>= 10ko) resulting in OpenUri returning a Tempfile" do
                let(:fetched_file) { 'image_150x150_28ko.png' }

                it { is_expected_to_return_the_right_metadata }
              end
            end
          end
        end

        describe "String object representing the signed reference to blob" do
          let(:attachable) do
            blob = ActiveStorage::Blob.create_and_upload!(
              io: File.open(png_image),
              filename: 'image_150x150.png',
              content_type: 'image/png',
              service_name: 'test'
            )
            blob.signed_id
          end

          it { is_expected_to_return_the_right_metadata }
        end

        describe "File object" do
          let(:attachable) { File.open(png_image) }

          if Rails.gem_version >= Gem::Version.new('7.1.0.rc1')
            it { is_expected_to_return_the_right_metadata }
          else
            it { is_expected_to_raise_error(ArgumentError, "Could not find or build blob: expected attachable, got #{attachable.inspect}") }
          end
        end

        describe "Pathname object" do
          let(:attachable) { Pathname.new(png_image) }

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
        describe "rotated image" do
          # Using a jpg file to test because the behaviour is uniform among OS,
          # we tried doing it with a png file but the result was different
          # between our local machine and the CI.
          let(:attachable) do
            ActiveStorage::Blob.create_and_upload!(
              io: File.open(Rails.root.join('public', 'image_700x500_rotated_90.jpg')),
              filename: 'image_700x500_rotated_90.jpg',
              content_type: 'image/jpeg',
              service_name: 'test'
            )
          end
          let(:expected_metadata) { { width: 700, height: 500 } }

          it { is_expected_to_return_the_right_metadata }
        end

        describe "0 byte size file" do
          let(:attachable) do
            ActiveStorage::Blob.create_and_upload!(
              io: File.open(Rails.root.join('public', 'image_file_0ko.png')),
              filename: 'image_150x150.png',
              content_type: 'image/png',
              service_name: 'test'
            )
          end

          it { is_expected_to_return_empty_metadata }
        end
      end
    end
  end
end
