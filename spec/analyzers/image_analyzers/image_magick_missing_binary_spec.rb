# frozen_string_literal: true

require "rails_helper"

RSpec.describe ActiveStorageValidations::Analyzer::ImageAnalyzer::ImageMagick do
  let(:path) { Rails.root.join("public", "image_150x150.png").to_s }
  let(:attachable) do
    {
      io: File.open(path),
      filename: "image_150x150.png",
      content_type: "image/png"
    }
  end
  let(:analyzer) { described_class.new(attachable) }
  let(:missing_binary) { "asv_missing_identify_#{Process.pid}" }

  context "when the ImageMagick CLI is missing" do
    context "when Process.spawn raises Errno::ENOENT" do
      before { allow(Process).to receive(:spawn).and_raise(Errno::ENOENT) }

      it "returns empty metadata" do
        expect(analyzer.metadata).to eq({})
      end
    end

    context "when the identify binary cannot be found" do
      before { allow(analyzer).to receive(:identify_command).and_return([ missing_binary, path ]) }

      it "returns empty metadata" do
        expect(analyzer.metadata).to eq({})
      end

      it "does not let Errno::ENOENT escape from #metadata" do
        expect { analyzer.metadata }.not_to raise_error
      end
    end

    describe "validator integration" do
      let(:identify_argv) { [ missing_binary, path ] }

      before do
        processor = ActiveStorage.variant_processor || ActiveStorageValidations::ASVAnalyzable::DEFAULT_IMAGE_PROCESSOR
        skip "requires the MiniMagick image processor" unless processor == :mini_magick

        # rubocop:disable RSpec/AnyInstance -- analyzer created internally by the validator
        allow_any_instance_of(described_class).to receive(:identify_command).and_return(identify_argv)
        # rubocop:enable RSpec/AnyInstance
      end

      context "with processable_file validation" do
        subject(:valid) { model.valid? }

        let(:model) { ProcessableFile::Validator::Check.new }

        before { model.has_to_be_processable.attach(image_150x150_file) }

        it "does not raise" do
          expect { valid }.not_to raise_error
        end

        it "is invalid" do
          expect(valid).to be(false)
        end

        it "adds a processable_file error" do
          valid
          expect(model.errors.any? { |error|
            error.options[:validator_type] == :processable_file
          }).to be(true)
        end
      end

      context "with dimension validation" do
        subject(:valid) { model.valid? }

        let(:model) { Dimension::Validator::Check.new }

        before { model.width.attach(image_150x150_file) }

        it "does not raise" do
          expect { valid }.not_to raise_error
        end

        it "is invalid" do
          expect(valid).to be(false)
        end

        it "adds a media metadata error" do
          valid
          expect(model.errors.any? { |error|
            error.type == :media_metadata_missing ||
              error.message.include?("not a valid media file")
          }).to be(true)
        end
      end
    end
  end
end
