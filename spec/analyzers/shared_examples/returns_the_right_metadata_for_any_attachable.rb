# frozen_string_literal: true

require "open-uri"

RSpec.shared_examples "returns the right metadata for any attachable" do
  describe "#metadata" do
    def is_expected_to_return_the_right_metadata
      expect(metadata).to eq(expected_metadata)
    end

    def is_expected_to_return_empty_metadata
      expect(metadata).to eq({})
    end

    subject(:metadata) { analyzer.metadata }

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
            service_name: "test"
          )
        end

        it { is_expected_to_return_the_right_metadata }

        # ImageMagick picks the decoder of formats without a magic number
        # (ICO, TGA) from the extension, like an uploaded file keeps it.
        it "is analyzed from a tempfile named with its extension" do
          analyzed_paths = []
          allow(analyzer).to receive(:media_from_path).and_wrap_original do |original, path|
            analyzed_paths << path
            original.call(path)
          end

          metadata

          expect(analyzed_paths).to all(end_with(media_extension))
          expect(analyzed_paths).not_to be_empty
        end
      end

      describe "ActionDispatch::Http::UploadedFile object" do
        let(:attachable) do
          tempfile = register_fixture_io(Tempfile.new([ media_filename, media_extension ]))
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
        let(:attachable) { register_uploaded_file(Rack::Test::UploadedFile.new(media_path, media_content_type)) }

        it { is_expected_to_return_the_right_metadata }

        context "when built on a StringIO" do
          let(:attachable) do
            Rack::Test::UploadedFile.new(StringIO.new(File.binread(media_path)), media_content_type, original_filename: media_filename)
          end

          it { is_expected_to_return_the_right_metadata }
        end
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

        context "when not passed with a content_type" do
          let(:attachable) do
            {
              io: media_io,
              filename: media_filename
            }
          end

          it { is_expected_to_return_the_right_metadata }
        end

        context "when the io is an IO-like object without a filesystem path" do
          # e.g. a streaming download wrapper: Rails only needs #read / #rewind
          # / #size, so the io is neither a File nor a StringIO here.
          let(:attachable) do
            {
              io: SimpleDelegator.new(StringIO.new(media_io.read)),
              filename: media_filename,
              content_type: media_content_type
            }
          end

          it { is_expected_to_return_the_right_metadata }
        end

        # `File.open(path) { |f| record.avatar.attach(io: f, …) }`: validated
        # after the block closed the file.
        context "when the io is a closed File" do
          let(:attachable) do
            file = File.open(media_path, "rb")
            file.close

            { io: file, filename: media_filename, content_type: media_content_type }
          end

          it { is_expected_to_return_the_right_metadata }
        end

        context "when the io is a Tempfile unlinked from the filesystem" do
          let(:attachable) do
            tempfile = register_fixture_io(Tempfile.new([ "asv", media_extension ], binmode: true))
            tempfile.write(File.binread(media_path))
            tempfile.rewind
            tempfile.unlink

            { io: tempfile, filename: media_filename, content_type: media_content_type }
          end

          it { is_expected_to_return_the_right_metadata }
        end

        # Ruby 3.4+: an anonymous Tempfile's #to_path is the tmp directory.
        if Gem::Version.new(RUBY_VERSION) >= Gem::Version.new("3.4")
          context "when the io is an anonymous Tempfile" do
            let(:attachable) do
              tempfile = register_fixture_io(Tempfile.create(anonymous: true).binmode)
              tempfile.write(File.binread(media_path))
              tempfile.rewind

              { io: tempfile, filename: media_filename, content_type: media_content_type }
            end

            it { is_expected_to_return_the_right_metadata }
          end
        end

        describe "Remote file" do
          before do
            stub_request(:get, url)
              .to_return(body: open_fixture(Rails.root.join("public", fetched_file)), status: 200)
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
            let(:io) { register_fixture_io(uri.open) }

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
            service_name: "test"
          )
          blob.signed_id
        end

        it { is_expected_to_return_the_right_metadata }
      end

      describe "File object" do
        let(:attachable) { media_io }

        if Rails.gem_version >= Gem::Version.new("7.1.0.rc1")
          it { is_expected_to_return_the_right_metadata }
        else
          it { is_expected_to_raise_error(ArgumentError, "Could not find or build blob: expected attachable, got #{attachable.inspect}") }
        end
      end

      describe "Pathname object" do
        let(:attachable) { Pathname.new(media_path) }

        if Rails.gem_version >= Gem::Version.new("7.1.0.rc1")
          it { is_expected_to_return_the_right_metadata }
        else
          it { is_expected_to_raise_error(ArgumentError, "Could not find or build blob: expected attachable, got #{attachable.inspect}") }
        end
      end

      if Rails.gem_version >= Gem::Version.new("7.1.0.rc1")
        # A relative path must not be read as a command-line option (`-…`) or
        # an ffmpeg protocol (`clip:…`) by the analyzer commands.
        describe "relative paths" do
          around do |example|
            Dir.mktmpdir do |dir|
              FileUtils.cp(media_path, File.join(dir, relative_filename))
              Dir.chdir(dir) { example.run }
            end
          end

          # `~$…` is an Office lock file name, not a home directory.
          %w[-%s clip:%s ~$%s].each do |pattern|
            context "when the filename looks like #{format(pattern, "file")}" do
              let(:relative_filename) { format(pattern, media_filename) }

              describe "File object" do
                let(:attachable) { open_fixture(relative_filename) }

                it { is_expected_to_return_the_right_metadata }
              end

              describe "Pathname object" do
                let(:attachable) { Pathname.new(relative_filename) }

                it { is_expected_to_return_the_right_metadata }
              end
            end
          end
        end
      end

      describe "something else" do
        let(:attachable) { 42 }

        it { is_expected_to_raise_error(ArgumentError, "Could not find or build blob: expected attachable, got #{attachable.inspect}") }
      end
    end

    describe "Edge cases" do
      if self.test_rotatable_media?
        describe "rotated media" do
          let(:attachable) do
            ActiveStorage::Blob.create_and_upload!(
              io: open_fixture(Rails.root.join("public", media_filename_rotated)),
              filename: media_filename_rotated,
              content_type: media_content_type_rotated,
              service_name: "test"
            )
          end
          let(:expected_metadata) { expected_metadata_rotated }

          it { is_expected_to_return_the_right_metadata }
        end
      end

      describe "0 byte size file" do
        let(:attachable) do
          ActiveStorage::Blob.create_and_upload!(
            io: open_fixture(Rails.root.join("public", media_filename_0ko)),
            filename: media_filename_0ko,
            content_type: media_content_type,
            service_name: "test"
          )
        end

        it { is_expected_to_return_empty_metadata }
      end
    end
  end
end
