module WorksWithAllowBlankOption
  extend ActiveSupport::Concern

  included do
    subject { validator_test_class::WithAllowBlank.new(params) }

    let(:file_matching_requirements) do
      case validator_sym
      when :aspect_ratio then image_150x150_file
      when :attached then image_150x150_file
      when :content_type then webp_file
      when :dimension then image_150x150_file
      when :limit then nil
      when :processable_image then image_150x150_file
      when :size then file_1ko
      end
    end
    let(:file_not_matching_requirements) do
      case validator_sym
      when :aspect_ratio then image_700x500_file
      when :attached then nil
      when :content_type then html_file
      when :dimension then image_700x500_file
      when :limit then file_5ko
      when :processable_image then tar_file_with_image_content_type
      when :size then file_5ko
      end
    end

    describe 'when passed a file matching the requirements' do
      before { subject.with_allow_blank.attach(file_matching_requirements) }

      it { is_expected_to_be_valid }
    end

    describe 'when passed a file not matching the requirements' do
      let(:error_options) { { allow_blank: true } }

      before { subject.with_allow_blank.attach(file_not_matching_requirements) }

      it { is_expected_not_to_be_valid }
      it { is_expected_to_have_error_options(error_options) }
    end
  end
end
