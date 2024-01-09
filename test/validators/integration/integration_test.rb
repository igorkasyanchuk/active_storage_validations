# frozen_string_literal: true

require 'test_helper'

describe 'Integration tests' do
  include ValidatorHelpers

  let(:integration_test_class) { Integration::Validator }
  let(:params) { {} }

  describe 'zero byte image' do
    let(:model) { integration_test_class::ZeroByteImage.new(params) }

    describe 'when provided with a zero byte image' do
      subject { model.zero_byte_image.attach(zero_byte_image_file) and model }

      let(:zero_byte_image_file) { image_file_0ko }

      let(:error_options) do
        {
          filename: image_file_0ko[:filename]
        }
      end

      it { is_expected_not_to_be_valid }
      it { is_expected_to_have_error_message("image_not_processable", error_options: error_options, validator: :processable_image) }
      it { is_expected_to_have_error_options(error_options, validator: :processable_image) }
    end
  end

  describe 'based on a file property' do
    let(:model) { integration_test_class::BasedOnAFileProperty.new(params) }

    describe 'when setting size constraints based on the content type' do
      describe "when passed a file with the right size and content content type" do
        subject { model.picture.attach(file_1ko_and_png) and model }

        it { is_expected_to_be_valid }
      end

      describe "when passed a file with a content type that should accept higher file size (<= 15.kilobytes)" do
        describe "and with a higher size that the one that can be accepted for all content types" do
          subject { model.picture.attach(file_17ko_and_png) and model }

          let(:error_options) do
            {
              file_size: '17 KB',
              min_size: nil,
              max_size: '15 KB'
            }
          end

          it { is_expected_not_to_be_valid }
          it { is_expected_to_have_error_message("file_size_not_less_than", error_options: error_options, validator: :size) }
          it { is_expected_to_have_error_options(error_options, validator: :size) }
        end
      end

      describe "when passed a file with a content type that should accept less file size (<= 5.kilobytes)" do
        describe "and with a higher size that the one that should be accepted" do
          subject { model.picture.attach(file_7ko_and_jpg) and model }

          let(:error_options) do
            {
              file_size: '7 KB',
              min_size: nil,
              max_size: '5 KB'
            }
          end

          it { is_expected_not_to_be_valid }
          it { is_expected_to_have_error_message("file_size_not_less_than", error_options: error_options, validator: :size) }
          it { is_expected_to_have_error_options(error_options, validator: :size) }
        end
      end
    end
  end
end
