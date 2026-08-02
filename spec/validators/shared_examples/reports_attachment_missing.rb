# frozen_string_literal: true

RSpec.shared_examples "reports attachment_missing" do
  context "when the attached file is missing from storage" do
    subject(:record) do
      blob = ActiveStorage::Blob.create_and_upload!(
        io: file_for_attachment_missing[:io],
        filename: file_for_attachment_missing[:filename],
        content_type: file_for_attachment_missing[:content_type]
      )
      blob.service.delete(blob.key)
      model.public_send(attribute).attach(blob)
      model
    end

    let(:error_options) do
      {
        filename: file_for_attachment_missing[:filename]
      }
    end

    it { is_expected_not_to_be_valid }
    it { is_expected_to_include_error_message("attachment_missing", error_options: error_options) }
    it { is_expected_to_have_error_options(error_options) }
  end
end
