module WorksWithIfOption
  extend ActiveSupport::Concern

  included do
    let(:file_matching_requirements) do
      case validator_sym
      when :aspect_ratio then image_150x150_file
      when :attached then image_150x150_file
      when :content_type then webp_file
      when :dimension then image_150x150_file
      when :limit then image_150x150_file
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
      when :limit then nil
      when :processable_image then tar_file_with_image_content_type
      when :size then file_5ko
      end
    end

    describe 'when the :if condition is met' do
      let(:params) { { title: 'Right title' } }

      describe 'and when passed a file matching the requirements' do
        before { subject.with_if.attach(file_matching_requirements) }

        it { is_expected_to_be_valid }
      end

      describe 'and when passed a file not matching the requirements' do
        before { subject.with_if.attach(file_not_matching_requirements) }

        it { is_expected_not_to_be_valid }
      end
    end
  end
end
