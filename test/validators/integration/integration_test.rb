# frozen_string_literal: true

require "test_helper"

describe "Integration tests" do
  include ValidatorHelpers

  let(:integration_test_class) { Integration::Validator }
  let(:params) { {} }

  describe "zero byte image" do
    let(:model) { integration_test_class::ZeroByteImage.new(params) }

    describe "when provided with a zero byte image" do
      subject { model.zero_byte_image.attach(zero_byte_image_file) and model }

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

    describe "when setting size constraints based on the content type" do
      describe "when passed a file with the right size and content content type" do
        subject { model.picture.attach(file_1ko_and_png) and model }

        it { is_expected_to_be_valid }
      end

      describe "when passed a file with a content type that should accept higher file size (<= 15.kilobytes)" do
        describe "and with a higher size that the one that can be accepted for all content types" do
          subject { model.picture.attach(file_17ko_and_png) and model }

          let(:error_options) do
            {
              file_size: "17 KB",
              min: nil,
              max: "15 KB"
            }
          end

          it { is_expected_not_to_be_valid }
          it { is_expected_to_include_error_message("file_size_not_less_than", error_options: error_options, validator: :size) }
          it { is_expected_to_have_error_options(error_options, validator: :size) }
        end
      end

      describe "when passed a file with a content type that should accept less file size (<= 5.kilobytes)" do
        describe "and with a higher size that the one that should be accepted" do
          subject { model.picture.attach(file_7ko_and_jpg) and model }

          let(:error_options) do
            {
              file_size: "7 KB",
              min: nil,
              max: "5 KB"
            }
          end

          it { is_expected_not_to_be_valid }
          it { is_expected_to_include_error_message("file_size_not_less_than", error_options: error_options, validator: :size) }
          it { is_expected_to_have_error_options(error_options, validator: :size) }
        end
      end
    end
  end

  describe "Performance" do
    describe "when the attachable blob has been analyzed by another metadata validator of our gem" do
      subject { integration_test_class::Performance.new(params) }

      describe "which uses the same metadata keys (e.g. width & height)" do
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
          subject.pictures.attach(attachable_1)
          subject.save!
        end

        it "only calls once a media analyzer (expensive operation) on the new attachable" do
          assert_called_on_instance_of(ActiveStorageValidations::Analyzer::ImageAnalyzer, :metadata, times: 1, returns: { width: 150, height: 150 }) do
            subject.pictures.attach(attachable_2)
          end
        end
      end

      describe "which uses different metadata keys (e.g. width & height + duration)" do
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
            "content_type" => "video/mp4"
          }
        end

        before do
          subject.videos.attach(attachable_1)
          subject.save!
        end

        it "calls once the corresponding media analyzers (expensive operation) on the new attachable" do
          assert_called_on_instance_of(ActiveStorageValidations::Analyzer::VideoAnalyzer, :metadata, times: 1, returns: { width: 150, height: 150, duration: 1.7, audio: false, video: true }) do
            assert_called_on_instance_of(ActiveStorageValidations::Analyzer::ContentTypeAnalyzer, :content_type, times: 1, returns: { content_type: "video/mp4" }) do
              subject.videos.attach(attachable_2)
            end
          end
        end

        it "save metadata keys from both analyses on the new attachable" do
          subject.valid?
          subject.videos.blobs.each do |blob|
            assert_equal expected_saved_metadata, blob.active_storage_validations_metadata
          end
        end
      end
    end
  end

  describe "Nested errors" do
    let(:parent_model) { integration_test_class::NestedErrorParent.create }
    let(:child_model) { integration_test_class::NestedErrorChild.new }

    describe "when updating the child model through attributes passed to the parent model" do
      describe "when the child model has an attachment that will cause a validation error" do
        subject { parent_model.update(child_attributes: { image: empty_io_file }) }

        before do
          parent_model.update!(child_attributes: { image: image_150x150_file })
        end

        it "does not allow to save the parent model" do
          assert_equal false, subject
        end
      end
    end
  end
end
