# frozen_string_literal: true

require "test_helper"

describe ActiveStorageValidations::Analyzer::ImageAnalyzer::ImageMagick do
  let(:path) { Rails.root.join("public", "image_150x150.png").to_s }
  let(:attachable) do
    {
      io: File.open(path),
      filename: "image_150x150.png",
      content_type: "image/png"
    }
  end
  let(:analyzer) { ActiveStorageValidations::Analyzer::ImageAnalyzer::ImageMagick.new(attachable) }
  let(:missing_binary) { "asv_missing_identify_#{Process.pid}" }

  describe "when the ImageMagick CLI is missing" do
    it "returns empty metadata when Process.spawn raises Errno::ENOENT" do
      Process.stub(:spawn, proc { raise Errno::ENOENT }) do
        assert_equal({}, analyzer.metadata)
      end
    end

    it "returns empty metadata when identify binary cannot be found" do
      analyzer.stub(:identify_command, [ missing_binary, path ]) do
        assert_equal({}, analyzer.metadata)
      end
    end

    it "does not let Errno::ENOENT escape from #metadata" do
      raised = false

      analyzer.stub(:identify_command, [ missing_binary, path ]) do
        begin
          analyzer.metadata
        rescue Errno::ENOENT
          raised = true
        end
      end

      refute raised, "Errno::ENOENT should be rescued and degraded to empty metadata"
    end

    describe "validator integration" do
      before do
        processor = ActiveStorage.variant_processor || ActiveStorageValidations::ASVAnalyzable::DEFAULT_IMAGE_PROCESSOR
        skip "requires the MiniMagick image processor" unless processor == :mini_magick
      end

      it "keeps processable_file validation from raising when identify is missing" do
        model = ProcessableFile::Validator::Check.new
        identify_argv = [ missing_binary, path ]

        ActiveStorageValidations::Analyzer::ImageAnalyzer::ImageMagick
          .stub_any_instance(:identify_command, identify_argv) do
            model.has_to_be_processable.attach(image_150x150_file)

            begin
              valid = model.valid?
            rescue Errno::ENOENT
              flunk "processable_file validation raised Errno::ENOENT when ImageMagick CLI is missing"
            end

            refute valid
            assert model.errors.any? { |error|
              error.options[:validator_type] == :processable_file
            }
          end
      end

      it "keeps dimension validation from raising when identify is missing" do
        model = Dimension::Validator::Check.new
        identify_argv = [ missing_binary, path ]

        ActiveStorageValidations::Analyzer::ImageAnalyzer::ImageMagick
          .stub_any_instance(:identify_command, identify_argv) do
            model.width.attach(image_150x150_file)

            begin
              valid = model.valid?
            rescue Errno::ENOENT
              flunk "dimension validation raised Errno::ENOENT when ImageMagick CLI is missing"
            end

            refute valid
            assert model.errors.any? { |error|
              error.type == :media_metadata_missing ||
                error.message.include?("not a valid media file")
            }
          end
      end
    end
  end
end
