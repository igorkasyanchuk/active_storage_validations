module WorksWithOnOption
  extend ActiveSupport::Concern

  included do
    subject { validator_test_class::WithOn.new(params) }

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

    %i(create update destroy custom).each do |context|
      describe ":#{context}" do
        describe 'when passed a file matching the requirements' do
          before { subject.with_on.attach(file_matching_requirements) }

          it { is_expected_to_be_valid(context: context) }
        end

        describe 'when passed a file not matching the requirements' do
          let(:error_options) { { on: %i[create update destroy custom] } }

          before { subject.with_on.attach(file_not_matching_requirements) }

          it { is_expected_not_to_be_valid(context: context) }
          it { is_expected_to_have_error_options(error_options, context: context) }
        end
      end
    end
  end
end
