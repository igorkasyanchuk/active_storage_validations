module ASVErrorable
  extend ActiveSupport::Concern

  included do
    subject { validator_test_class::AsvErrorable.new(params) }

    let(:file_not_matching_requirements) do
      case validator_sym
      when :aspect_ratio then image_700x500_file
      when :content_type then html_file
      when :dimension then image_700x500_file
      when :duration then audio_5s
      when :processable_file then tar_file_with_image_content_type
      when :size then file_5ko
      when :pages then pdf_7_pages_file
      end
    end
    let(:error_options) { { filename: file_not_matching_requirements[:filename] } }

    describe "when passed a file not matching validation requirements" do
      before { subject.asv_errorable.attach(file_not_matching_requirements) }

      it { is_expected_not_to_be_valid(context: :create) }
      it { is_expected_to_have_error_options(error_options, context: :create) }
    end
  end
end
