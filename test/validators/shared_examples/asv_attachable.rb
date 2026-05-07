module ASVAttachable
  extend ActiveSupport::Concern

  included do
    subject { validator_test_class::AsvAttachable.new(params) }

    let(:file_matching_requirements) do
      case validator_sym
      when :aspect_ratio then image_150x150_file
      when :attached then # n/a
      when :content_type then webp_file
      when :dimension then image_150x150_file
      when :duration then audio_1s
      when :limit then nil # n/a
      when :processable_file then image_150x150_file
      when :size then file_1ko
      when :total_size then file_1ko
      when :pages then pdf_5_pages_file
      end
    end
    let(:file_not_matching_requirements) do
      case validator_sym
      when :aspect_ratio then image_1920x1080_file
      when :attached then nil # n/a
      when :content_type then pdf_file
      when :dimension then image_1920x1080_file
      when :duration then audio_10s
      when :limit then nil # n/a
      when :processable_file then tar_file_with_image_content_type
      when :size then file_5ko
      when :total_size then file_28ko
      when :pages then pdf_7_pages_file
      end
    end
    let(:valid_blob) do
      ActiveStorage::Blob.create_and_upload!(
        io: file_matching_requirements[:io],
        filename: file_matching_requirements[:filename],
        content_type: file_matching_requirements[:content_type]
      )
    end

    describe "when the same blob is present both as an ActiveStorage::Blob object (existing attachment) and as a String signed_id (new attachable)" do
      before do
        subject.save!
        subject.asv_attachables.attach(valid_blob)
      end

      it "allows to attach the blob as a String signed_id (new attachable)" do
        subject.asv_attachables.attach(valid_blob.signed_id)

        assert(subject.valid?)
      end

      it "allows to attach the same signed_id multiple times" do
        subject.asv_attachables.attach([ valid_blob.signed_id, valid_blob.signed_id ])

        assert(subject.valid?)
      end

      it "allows to attach the blob as both Blob object and multiple signed_ids" do
        subject.asv_attachables.attach([ blob, valid_blob.signed_id, valid_blob.signed_id ])

        assert(subject.valid?)
      end
    end

    describe "when an invalid file is attached alongside a duplicate signed_id" do
      before do
        subject.save!
        subject.asv_attachables.attach(valid_blob)
      end

      it "still reports errors for the invalid file even when a duplicate valid blob is present" do
        next if file_not_matching_requirements.nil? # validators like :limit or :attached don't apply here

        invalid_blob = ActiveStorage::Blob.create_and_upload!(
          io: file_not_matching_requirements[:io],
          filename: file_not_matching_requirements[:filename],
          content_type: file_not_matching_requirements[:content_type]
        )

        subject.asv_attachables.attach([ valid_blob.signed_id, invalid_blob ])

        assert(subject.invalid?)
      end
    end
  end
end
