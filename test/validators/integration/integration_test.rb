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
end
