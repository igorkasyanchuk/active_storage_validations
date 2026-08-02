# frozen_string_literal: true

RSpec.shared_examples "works with strict option" do
  subject(:model) { validator_test_class::WithStrict.new(params) }

  let(:file_matching_requirements) do
    case validator_sym
    when :aspect_ratio then image_150x150_file
    when :attached then image_150x150_file
    when :content_type then webp_file
    when :dimension then image_150x150_file
    when :duration then audio_1s
    when :limit then image_150x150_file
    when :processable_file then image_150x150_file
    when :size then file_1ko
    when :total_size then [ blob_file_0_5ko, blob_file_0_5ko ]
    when :pages then pdf_5_pages_file
    end
  end
  let(:file_not_matching_requirements) do
    case validator_sym
    when :aspect_ratio then image_700x500_file
    when :attached then nil
    when :content_type then html_file
    when :dimension then image_700x500_file
    when :duration then audio_5s
    when :limit then nil
    when :processable_file then tar_file_with_image_content_type
    when :size then file_5ko
    when :total_size then [ blob_file_5ko, blob_file_5ko ]
    when :pages then pdf_7_pages_file
    end
  end

  context "when passed a file matching the requirements" do
    before { subject.with_strict.attach(file_matching_requirements) }

    it { is_expected_to_be_valid }
  end

  context "when passed a file not matching the requirements" do
    let(:error_class) { subject.class::StrictException }
    let(:error_options) { { strict: error_class } }

    before { subject.with_strict.attach(file_not_matching_requirements) }

    it { is_expected_to_raise_error(error_class, "With strict") }
  end
end
