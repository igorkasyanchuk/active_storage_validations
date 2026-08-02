# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Integration tests" do
  let(:integration_test_class) { Integration::Validator }
  let(:params) { {} }

  describe "zero byte image" do
    let(:model) { integration_test_class::ZeroByteImage.new(params) }

    context "when provided with a zero byte image" do
      subject(:record) { model.zero_byte_image.attach(zero_byte_image_file) and model }

      let(:zero_byte_image_file) { image_file_0ko }

      let(:error_options) do
        {
          filename: image_file_0ko[:filename]
        }
      end

      it { is_expected_not_to_be_valid }
      it { is_expected_to_include_error_message("file_not_processable", error_options: error_options, validator: :processable_file) }
      it { is_expected_to_have_error_options(error_options, validator: :processable_file) }
    end
  end

  describe "based on a file property" do
    let(:model) { integration_test_class::BasedOnAFileProperty.new(params) }

    context "when setting size constraints based on the content type" do
      context "when passed a file with the right size and content content type" do
        subject(:record) { model.picture.attach(file_1ko_and_png) and model }

        it { is_expected_to_be_valid }
      end

      context "when passed a file with a content type that should accept higher file size (<= 15.kilobytes)" do
        context "and with a higher size that the one that can be accepted for all content types" do
          subject(:record) { model.picture.attach(file_17ko_and_png) and model }

          let(:error_options) do
            {
              file_size: "17 KB",
              min: nil,
              max: "15 KB"
            }
          end

          it { is_expected_not_to_be_valid }
          it { is_expected_to_include_error_message("file_size_not_less_than", with_locales: [ "en" ], error_options: error_options, validator: :size) }
          it { is_expected_to_have_error_options(error_options, validator: :size) }
        end
      end

      context "when passed a file with a content type that should accept less file size (<= 5.kilobytes)" do
        context "and with a higher size that the one that should be accepted" do
          subject(:record) { model.picture.attach(file_7ko_and_jpg) and model }

          let(:error_options) do
            {
              file_size: "7 KB",
              min: nil,
              max: "5 KB"
            }
          end

          it { is_expected_not_to_be_valid }
          it { is_expected_to_include_error_message("file_size_not_less_than", with_locales: [ "en" ], error_options: error_options, validator: :size) }
          it { is_expected_to_have_error_options(error_options, validator: :size) }
        end
      end
    end
  end

  describe "Performance" do
    context "when the attachable blob has been analyzed by another metadata validator of our gem" do
      subject(:model) { integration_test_class::Performance.new(params) }

      context "which uses the same metadata keys (e.g. width & height)" do
        let(:attachable_1) do
          {
            io: File.open(Rails.root.join("public", "image_150x150.png")),
            filename: "image_150x150.png",
            content_type: "image/png"
          }
        end
        let(:attachable_2) do
          {
            io: File.open(Rails.root.join("public", "image_150x150.png")),
            filename: "image_150x150_2.png",
            content_type: "image/png"
          }
        end

        before do
          model.pictures.attach(attachable_1)
          model.save!
        end

        it "only calls once a media analyzer (expensive operation) on the new attachable" do
          # rubocop:disable RSpec/AnyInstance -- analyzer created internally by the validator
          expect_any_instance_of(ActiveStorageValidations::Analyzer::ImageAnalyzer).to receive(:metadata).once.and_return({ width: 150, height: 150 })
          # rubocop:enable RSpec/AnyInstance
          model.pictures.attach(attachable_2)
        end
      end

      context "which uses different metadata keys (e.g. width & height + duration)" do
        let(:attachable_1) do
          {
            io: File.open(Rails.root.join("public", "video_150x150.mp4")),
            filename: "video_150x150.mp4",
            content_type: "video/mp4"
          }
        end
        let(:attachable_2) do
          {
            io: File.open(Rails.root.join("public", "video_150x150.mp4")),
            filename: "video_150x150_2.mp4",
            content_type: "video/mp4"
          }
        end
        let(:expected_saved_metadata) do
          {
            "width" => 150,
            "height" => 150,
            "duration" => 1.7,
            "audio" => false,
            "video" => true,
            "content_type" => "video/mp4",
            "content_type_backend" => "file"
          }
        end

        before do
          model.videos.attach(attachable_1)
          model.save!
        end

        it "calls once the corresponding media analyzers (expensive operation) on the new attachable" do
          # rubocop:disable RSpec/AnyInstance -- analyzer created internally by the validator
          expect_any_instance_of(ActiveStorageValidations::Analyzer::VideoAnalyzer).to receive(:metadata).once.and_return({ width: 150, height: 150, duration: 1.7, audio: false, video: true })
          expect_any_instance_of(ActiveStorageValidations::Analyzer::ContentTypeAnalyzer::File).to receive(:content_type).once.and_return({ content_type: "video/mp4", content_type_backend: "file" })
          # rubocop:enable RSpec/AnyInstance
          model.videos.attach(attachable_2)
        end

        it "save metadata keys from both analyses on the new attachable" do
          model.valid?
          model.videos.blobs.each do |blob|
            expect(blob.active_storage_validations_metadata).to eq(expected_saved_metadata)
          end
        end
      end
    end
  end

  describe "Nested errors" do
    let(:parent_model) { integration_test_class::NestedErrorParent.create }
    let(:child_model) { integration_test_class::NestedErrorChild.new }

    context "when updating the child model through attributes passed to the parent model" do
      context "when the child model has an attachment that will cause a validation error" do
        subject(:result) { parent_model.update(child_attributes: { image: empty_io_file }) }

        before do
          parent_model.update!(child_attributes: { image: image_150x150_file })
        end

        it "does not allow to update the parent model" do
          expect(result).to be(false)
        end

        it "adds the child model's error to the parent model's errors" do
          result

          expect(parent_model.errors.any?).to be(true)
        end
      end
    end
  end
end
