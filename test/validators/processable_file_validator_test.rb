# frozen_string_literal: true

require 'test_helper'
require 'validators/shared_examples/works_fine_with_attachables'
require 'validators/shared_examples/works_with_all_rails_common_validation_options'

describe ActiveStorageValidations::ProcessableFileValidator do
  include ValidatorHelpers

  let(:validator_test_class) { ProcessableFile::Validator }
  let(:params) { {} }

  describe 'Validator checks' do
    include WorksFineWithAttachables

    let(:model) { validator_test_class::Check.new(params) }

    %w(image video audio).each do |media_type|
      describe "when provided with a #{media_type} that is processable" do
        # validates :has_to_be_processable, processable_file: true
        subject { model.has_to_be_processable.attach(processable_file) and model }

        let(:processable_file) do
          case media_type
          when 'image' then image_1920x1080_file
          when 'video' then video_file
          when 'audio' then audio_file
          end
        end

        it { is_expected_to_be_valid }
      end
    end

    describe 'when provided with a file that is not processable' do
      # validates :has_to_be_processable, processable_file: true
      subject { model.has_to_be_processable.attach(tar_file_with_image_content_type) and model }

      let(:error_options) do
        {
          filename: '404.png'
        }
      end

      it { is_expected_not_to_be_valid }
      it { is_expected_to_have_error_message("file_not_processable", error_options: error_options) }
      it { is_expected_to_have_error_options(error_options) }
    end

    describe 'when provided with a StringIO that is an image' do
      # validates :has_to_be_processable, processable_file: true
      subject { model.has_to_be_processable.attach(image_string_io) and model }

      it { is_expected_to_be_valid }
    end
  end

  describe 'Rails options' do
    include WorksWithAllRailsCommonValidationOptions
  end
end
