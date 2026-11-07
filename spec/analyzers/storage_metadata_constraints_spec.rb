# frozen_string_literal: true

require "rails_helper"

# Everything an analyzer returns is cached on the blob as `asv_*` custom
# metadata, and Active Storage forwards blob custom metadata to the storage
# service as object metadata. S3 caps user-defined metadata at 2 KB (UTF-8
# bytes of every key and value) and only accepts ASCII, and that budget is
# shared with the app's own custom metadata. Analyzers may therefore only
# return small scalar values: no free-form hashes such as audio stream tags,
# no long or non-ASCII strings.
#
# Every analyzer is run over every dummy fixture it could be asked to analyze.
RSpec.describe ActiveStorageValidations::Analyzer do
  describe "storage metadata constraints" do
    # https://docs.aws.amazon.com/AmazonS3/latest/userguide/UsingMetadata.html#UserMetadata
    let(:s3_user_defined_metadata_limit) { 2.kilobytes }

    # What ASVBlobMetadatable would write into `blob.metadata["custom"]`, i.e.
    # what the storage service receives.
    def storage_metadata_for(result)
      blob = ActiveStorage::Blob.new
      blob.merge_into_active_storage_validations_metadata(result)
      blob.metadata["custom"]
    end

    # Class-level helpers: they build the example matrix below.
    def self.analyzers_for(content_type)
      analyzers = [ ActiveStorageValidations::Analyzer::ContentTypeAnalyzer::File ]

      case content_type
      when %r{\Aimage/}
        analyzers << ActiveStorageValidations::Analyzer::ImageAnalyzer::ImageMagick
        analyzers << ActiveStorageValidations::Analyzer::ImageAnalyzer::Vips
      when %r{\Avideo/}
        # A video container may only hold audio (e.g. MediaRecorder WebM recordings)
        analyzers << ActiveStorageValidations::Analyzer::VideoAnalyzer
        analyzers << ActiveStorageValidations::Analyzer::AudioAnalyzer
      when %r{\Aaudio/}
        analyzers << ActiveStorageValidations::Analyzer::AudioAnalyzer
      when "application/pdf"
        analyzers << ActiveStorageValidations::Analyzer::PdfAnalyzer
      end

      analyzers
    end

    def self.example_metadata_for(analyzer_class)
      case analyzer_class.name.demodulize
      when "ImageMagick" then { image_processor: :mini_magick }
      when "Vips" then { image_processor: :vips }
      else {}
      end
    end

    fixtures = Rails.root.join("public").children
                    .select { |path| path.file? && !path.basename.to_s.start_with?(".") }
                    .sort_by { |path| path.basename.to_s }

    fixtures.each do |fixture|
      analyzers_for(Marcel::MimeType.for(name: fixture.basename.to_s)).each do |analyzer_class|
        context "when #{analyzer_class.name.demodulize} analyzes #{fixture.basename}", **example_metadata_for(analyzer_class) do
          subject(:stored_metadata) { storage_metadata_for(result) }

          let(:attachable) do
            {
              io: open_fixture(fixture),
              filename: fixture.basename.to_s,
              content_type: Marcel::MimeType.for(name: fixture.basename.to_s)
            }
          end
          let(:analyzer) { analyzer_class.new(attachable) }
          let(:result) do
            analyzer_class <= ActiveStorageValidations::Analyzer::ContentTypeAnalyzer ? analyzer.content_type : analyzer.metadata
          end

          it "returns scalar values only" do
            expect(result.values).to all(be_a(Numeric).or(be_a(String)).or(be(true)).or(be(false)))
          end

          it "stores ASCII-only keys and values" do
            expect(stored_metadata.keys + stored_metadata.values).to all(satisfy("be ASCII-only", &:ascii_only?))
          end

          it "stays within the S3 user-defined metadata limit" do
            expect(stored_metadata.sum { |key, value| key.bytesize + value.bytesize }).to be <= s3_user_defined_metadata_limit
          end
        end
      end
    end
  end
end
