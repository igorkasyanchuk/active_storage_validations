# frozen_string_literal: true

RSpec.shared_examples "ASVAttachable" do
  subject(:model) { validator_test_class::AsvAttachable.new(params) }

  let(:file_matching_requirements) do
    case validator_sym
    when :aspect_ratio then image_150x150_file
    when :attached then # n/a
    when :content_type then webp_file
    when :dimension then image_150x150_file
    when :duration then audio_1s
    when :with_audio then video_with_audio_file
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
    when :with_audio then video_file
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

  context "when the same blob is present both as an ActiveStorage::Blob object (existing attachment) and as a String signed_id (new attachable)" do
    before do
      subject.save!
      subject.asv_attachables.attach(valid_blob)
    end

    it "allows to attach the blob as a String signed_id (new attachable)" do
      subject.asv_attachables.attach(valid_blob.signed_id)

      expect(subject.valid?).to be(true)
    end

    it "allows to attach the same signed_id multiple times" do
      subject.asv_attachables.attach([ valid_blob.signed_id, valid_blob.signed_id ])

      expect(subject.valid?).to be(true)
    end

    it "allows to attach the blob as both Blob object and multiple signed_ids" do
      subject.asv_attachables.attach([ valid_blob, valid_blob.signed_id, valid_blob.signed_id ])

      expect(subject.valid?).to be(true)
    end
  end

  context "when an invalid file is attached alongside a duplicate signed_id" do
    before do
      subject.save!
      subject.asv_attachables.attach(valid_blob)
    end

    it "still reports errors for the invalid file even when a duplicate valid blob is present" do
      skip if file_not_matching_requirements.nil? # validators like :limit or :attached don't apply here

      invalid_blob = ActiveStorage::Blob.create_and_upload!(
        io: file_not_matching_requirements[:io],
        filename: file_not_matching_requirements[:filename],
        content_type: file_not_matching_requirements[:content_type]
      )

      subject.asv_attachables.attach([ valid_blob.signed_id, invalid_blob ])

      expect(subject.invalid?).to be(true)
    end
  end

  describe "attachments marked for destruction" do
    before do
      skip if file_not_matching_requirements.nil? # validators like :limit or :attached don't apply here
    end

    describe "one" do
      before do
        skip if validator_sym == :total_size # has_many_attached only

        subject.asv_attachable.attach(file_not_matching_requirements)
        subject.save!(validate: false)
      end

      it "still reports errors for the persisted invalid file" do
        expect(subject.invalid?).to be(true)
      end

      it "ignores the persisted invalid file once marked for destruction" do
        subject.asv_attachable.mark_for_destruction

        expect(subject.valid?).to be(true)
      end
    end

    describe "many" do
      before do
        subject.asv_attachables.attach(file_not_matching_requirements)
        subject.save!(validate: false)
      end

      it "ignores the persisted invalid file once marked for destruction when a new file is attached" do
        subject.asv_attachables.first.mark_for_destruction
        subject.asv_attachables.attach(file_matching_requirements)

        expect(subject.valid?).to be(true)
      end
    end
  end

  context "when multiple new files are attached at once" do
    it "still reports errors for the invalid file when another new file is valid" do
      skip if file_not_matching_requirements.nil? # validators like :limit or :attached don't apply here

      subject.asv_attachables.attach([ file_matching_requirements, file_not_matching_requirements ])

      expect(subject.invalid?).to be(true)
    end
  end
end
