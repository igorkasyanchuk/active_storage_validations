# frozen_string_literal: true

require 'test_helper'
require 'validators/shared_examples/works_with_all_rails_common_validation_options'

describe ActiveStorageValidations::ProcessableImageValidator do
  include ValidatorHelpers

  let(:validator_test_class) { ProcessableImage::Validator }
  let(:params) { {} }

  describe 'Validator checks' do
    let(:model) { validator_test_class::Check.new(params) }

    describe 'when provided with an image that is processable' do
      # validates :has_to_be_processable, processable_image: true
      subject { model.has_to_be_processable.attach(image_1920x1080_file) and model }

      it { is_expected_to_be_valid }
    end

    describe 'when provided with an image that is not processable' do
      # validates :has_to_be_processable, processable_image: true
      subject { model.has_to_be_processable.attach(tar_file_with_image_content_type) and model }

      let(:error_options) do
        {
          filename: '404.png'
        }
      end

      it { is_expected_not_to_be_valid }
      it { is_expected_to_have_error_message("image_not_processable", error_options: error_options) }
      it { is_expected_to_have_error_options(error_options) }
    end

    describe 'when provided with a StringIO that is an image' do
      # validates :has_to_be_processable, processable_image: true
      subject { model.has_to_be_processable.attach(image_string_io) and model }

      it { is_expected_to_be_valid }
    end
  end

  describe 'Rails options' do
    include WorksWithAllRailsCommonValidationOptions
  end
end
