# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Legacy multi-validator integration" do
  describe "User presence" do
    subject(:user) { User.new(name: "John Smith") }

    it "requires avatar and photos (and proc counterparts)" do
      expect(user).not_to be_valid
      expect(user.errors.full_messages).to eq([
        "Avatar must not be blank",
        "Photos can't be blank",
        "Proc avatar must not be blank",
        "Proc photos can't be blank"
      ])
    end

    context "when only avatars are attached" do
      before do
        user.avatar.attach(image_150x150_file)
        user.proc_avatar.attach(image_150x150_file)
      end

      it "still requires photos" do
        expect(user).not_to be_valid
        expect(user.errors.full_messages).to eq([
          "Photos can't be blank",
          "Proc photos can't be blank"
        ])
      end
    end

    context "when only photos are attached" do
      before do
        user.photos.attach(image_150x150_file)
        user.proc_photos.attach(image_150x150_file)
      end

      it "still requires avatars" do
        expect(user).not_to be_valid
        expect(user.errors.full_messages).to eq([
          "Avatar must not be blank",
          "Proc avatar must not be blank"
        ])
      end
    end
  end

  describe "User content type" do
    subject(:user) { User.new(name: user_name) }

    let(:user_name) { "John Smith" }

    context "when photos have an invalid content type" do
      before do
        user.avatar.attach(image_150x150_file)
        user.proc_avatar.attach(image_150x150_file)
        user.image_regex.attach(image_150x150_file)
        user.proc_image_regex.attach(image_150x150_file)
        user.photos.attach(bad_dummy_file)
        user.proc_photos.attach(bad_dummy_file)
        user.video.attach(video_file)
      end

      it "rejects the photos" do
        expect(user).not_to be_valid
        expect(user.errors.full_messages).to eq([
          'Photos has an invalid content type (authorized content types are PNG, JPG, \\A.*/pdf\\z)',
          'Proc photos has an invalid content type (authorized content types are PNG, JPG, \\A.*/pdf\\z)'
        ])
      end
    end

    context "when avatar has an invalid content type" do
      before do
        user.avatar.attach(bad_dummy_file)
        user.proc_avatar.attach(bad_dummy_file)
        user.image_regex.attach(image_150x150_file)
        user.proc_image_regex.attach(image_150x150_file)
        user.photos.attach(image_150x150_file)
        user.proc_photos.attach(image_150x150_file)
        user.video.attach(video_file)
      end

      it "rejects the avatar and exposes error details" do
        expect(user).not_to be_valid
        expect(user.errors.full_messages).to eq([
          "Avatar has an invalid content type (authorized content type is PNG)",
          "Proc avatar has an invalid content type (authorized content type is PNG)"
        ])
        expect(user.errors.details).to eq(
          avatar: [
            {
              error: :content_type_invalid,
              validator_type: :content_type,
              authorized_human_content_types: "PNG",
              content_type: "text/plain",
              human_content_type: "TXT",
              count: 1,
              filename: "apple-touch-icon.png"
            }
          ],
          proc_avatar: [
            {
              error: :content_type_invalid,
              validator_type: :content_type,
              authorized_human_content_types: "PNG",
              content_type: "text/plain",
              human_content_type: "TXT",
              count: 1,
              filename: "apple-touch-icon.png"
            }
          ]
        )
      end
    end

    context "when photos are PDFs matched by regex" do
      before do
        user.avatar.attach(image_150x150_file)
        user.proc_avatar.attach(image_150x150_file)
        user.image_regex.attach(image_150x150_file)
        user.proc_image_regex.attach(image_150x150_file)
        user.photos.attach(pdf_file)
        user.proc_photos.attach(pdf_file)
        user.video.attach(video_file)
      end

      it { is_expected.to be_valid }
    end

    context "when image_regex has an invalid content type" do
      before do
        user.avatar.attach(image_150x150_file)
        user.proc_avatar.attach(image_150x150_file)
        user.image_regex.attach(bad_dummy_file)
        user.proc_image_regex.attach(bad_dummy_file)
        user.photos.attach(image_150x150_file)
        user.proc_photos.attach(image_150x150_file)
        user.video.attach(video_file)
      end

      it "rejects the image_regex attachments" do
        expect(user).not_to be_valid
        expect(user.errors.full_messages).to eq([
          'Image regex has an invalid content type (authorized content type is \\Aimage/.*\\z)',
          'Proc image regex has an invalid content type (authorized content type is \\Aimage/.*\\z)'
        ])
      end
    end

    context "when multiple attachments have invalid content types" do
      before do
        user.avatar.attach(bad_dummy_file)
        user.proc_avatar.attach(bad_dummy_file)
        user.image_regex.attach(bad_dummy_file)
        user.proc_image_regex.attach(bad_dummy_file)
        user.photos.attach(bad_dummy_file)
        user.proc_photos.attach(bad_dummy_file)
        user.video.attach(video_file)
      end

      it "reports all invalid content types" do
        expect(user).not_to be_valid
        expect(user.errors.full_messages).to eq([
          "Avatar has an invalid content type (authorized content type is PNG)",
          'Photos has an invalid content type (authorized content types are PNG, JPG, \\A.*/pdf\\z)',
          'Image regex has an invalid content type (authorized content type is \\Aimage/.*\\z)',
          "Proc avatar has an invalid content type (authorized content type is PNG)",
          'Proc photos has an invalid content type (authorized content types are PNG, JPG, \\A.*/pdf\\z)',
          'Proc image regex has an invalid content type (authorized content type is \\Aimage/.*\\z)'
        ])
      end
    end

    context "when conditional content type applies" do
      let(:user_name) { "Peter Griffin" }

      context "with valid files" do
        before do
          user.avatar.attach(image_150x150_file)
          user.proc_avatar.attach(image_150x150_file)
          user.photos.attach(image_150x150_file)
          user.proc_photos.attach(image_150x150_file)
          user.conditional_image_2.attach(image_150x150_file)
          user.video.attach(video_file)
        end

        it "is valid" do
          expect(user).to be_valid
          expect(user.errors.full_messages).to eq([])
        end
      end

      context "with invalid files" do
        before do
          user.avatar.attach(bad_dummy_file)
          user.proc_avatar.attach(bad_dummy_file)
          user.photos.attach(bad_dummy_file)
          user.proc_photos.attach(image_150x150_file)
          user.conditional_image_2.attach(bad_dummy_file)
          user.video.attach(video_file)
        end

        it "rejects the invalid attachments" do
          expect(user).not_to be_valid
          expect(user.errors.full_messages).to eq([
            "Avatar has an invalid content type (authorized content type is PNG)",
            "Photos has an invalid content type (authorized content types are PNG, JPG, \\A.*/pdf\\z)",
            "Conditional image 2 has an invalid content type (authorized content type is \\Aimage/.*\\z)",
            "Proc avatar has an invalid content type (authorized content type is PNG)"
          ])
        end
      end
    end
  end

  describe "Project file limits" do
    subject(:project) { Project.new(title: "Death Star") }

    context "when too many files are attached" do
      before do
        project.documents.attach([ pdf_file, pdf_file, pdf_file, pdf_file ])
        project.proc_documents.attach([ pdf_file, pdf_file, pdf_file, pdf_file ])
      end

      it "validates the maximum number of files" do
        expect(project).not_to be_valid
        expect(project.errors.full_messages).to eq([
          "Documents total number of files must be between 1 and 3 files (there are 4 files attached)",
          "Proc documents total number of files must be between 1 and 3 files (there are 4 files attached)"
        ])
      end
    end

    context "when required documents are missing" do
      before { project.proc_documents.attach(pdf_file) }

      it "validates the minimum number of files" do
        expect(project).not_to be_valid
        expect(project.errors.full_messages).to eq([
          "Documents no files attached (must have between 1 and 3 files)"
        ])
      end
    end
  end

  describe "LimitAttachment file limits" do
    subject(:limit_attachment) { LimitAttachment.create(name: "klingon") }

    context "when more than the maximum number of files are attached" do
      before do
        limit_attachment.files.attach([ pdf_file, pdf_file, pdf_file, pdf_file, pdf_file, pdf_file ])
        limit_attachment.proc_files.attach([ pdf_file, pdf_file, pdf_file, pdf_file, pdf_file, pdf_file ])
      end

      it "rejects before persist and keeps in-memory counts" do
        expect(limit_attachment).not_to be_valid
        expect(limit_attachment.files.count).to eq(6)
        expect(limit_attachment.proc_files.count).to eq(6)
        expect(limit_attachment.files_blobs.count).to eq(0)
        expect(limit_attachment.proc_files_blobs.count).to eq(0)
        expect(limit_attachment.errors.full_messages).to eq([
          "Files too many files attached (maximum is 4 files, got 6)",
          "Proc files too many files attached (maximum is 4 files, got 6)"
        ])

        expect(limit_attachment).not_to be_valid
        expect(limit_attachment.errors.full_messages).to eq([
          "Files too many files attached (maximum is 4 files, got 6)",
          "Proc files too many files attached (maximum is 4 files, got 6)"
        ])
      end
    end

    context "when files are within the limit" do
      before do
        limit_attachment.files.attach([ pdf_file, pdf_file, pdf_file ])
        limit_attachment.proc_files.attach([ pdf_file, pdf_file, pdf_file ])
      end

      it "allows saving and purging" do
        expect(limit_attachment).to be_valid
        expect(limit_attachment.files.count).to eq(3)
        expect(limit_attachment.proc_files.count).to eq(3)
        expect(limit_attachment.save).to be(true)

        limit_attachment.reload
        expect(limit_attachment.files_blobs.count).to eq(3)
        expect(limit_attachment.proc_files_blobs.count).to eq(3)

        limit_attachment.files.first.purge
        limit_attachment.proc_files.first.purge

        expect(limit_attachment).to be_valid
        limit_attachment.reload
        expect(limit_attachment.files_blobs.count).to eq(2)
        expect(limit_attachment.proc_files_blobs.count).to eq(2)
      end
    end

    context "when five files are attached" do
      before do
        limit_attachment.files.attach([ pdf_file, pdf_file, pdf_file, pdf_file, pdf_file ])
        limit_attachment.proc_files.attach([ pdf_file, pdf_file, pdf_file, pdf_file, pdf_file ])
      end

      it "does not save" do
        expect(limit_attachment).not_to be_valid
        expect(limit_attachment.files.count).to eq(5)
        expect(limit_attachment.proc_files.count).to eq(5)
        expect(limit_attachment.save).to be(false)
      end
    end
  end

  describe "OnlyImage dimensions and content type" do
    subject(:only_image) { OnlyImage.new }

    context "when a non-image file is attached" do
      before do
        only_image.image.attach(html_file)
        only_image.proc_image.attach(html_file)
      end

      it "rejects the file" do
        expect(only_image).not_to be_valid
        expect(only_image.errors.full_messages).to eq([
          "Image is not a valid media file",
          "Image is not a valid media file",
          "Image has an invalid content type (authorized content types are PNG, JPG)",
          "Proc image is not a valid media file",
          "Proc image is not a valid media file",
          "Proc image has an invalid content type (authorized content types are PNG, JPG)"
        ])
      end
    end

    context "when a valid 16:9 image is attached" do
      before do
        only_image.image.attach(image_1920x1080_file)
        only_image.proc_image.attach(image_1920x1080_file)
        only_image.another_image.attach(image_1920x1080_file)
      end

      it { is_expected.to be_valid }
    end

    context "when a PDF is attached" do
      before do
        only_image.image.attach(pdf_file)
        only_image.proc_image.attach(pdf_file)
      end

      it "rejects the content type" do
        expect(only_image).not_to be_valid
        expect(only_image.errors.full_messages).to include(
          "Image has an invalid content type (authorized content types are PNG, JPG)"
        )
      end
    end

    context "when another_image is unprocessable" do
      before do
        only_image.image.attach(image_1920x1080_file)
        only_image.proc_image.attach(image_1920x1080_file)
        only_image.another_image.attach(tar_file_with_image_content_type)
      end

      it "rejects the unprocessable file" do
        expect(only_image).not_to be_valid
        expect(only_image.errors.full_messages).to eq([
          "Another image is not identified as a valid media file"
        ])
      end
    end

    context "when any_image is unprocessable but processable_file is false" do
      before do
        only_image.image.attach(image_1920x1080_file)
        only_image.proc_image.attach(image_1920x1080_file)
        only_image.any_image.attach(tar_file_with_image_content_type)
      end

      it { is_expected.to be_valid }
    end

    context "when images are attached via StringIO" do
      before do
        only_image.image.attach(image_string_io)
        only_image.proc_image.attach(image_string_io)
        only_image.another_image.attach(image_string_io)
        only_image.any_image.attach(image_string_io)
      end

      it { is_expected.to be_valid }
    end
  end

  describe "Project dimensions" do
    subject(:project) { Project.new(title: "Death Star") }

    before do
      project.documents.attach(pdf_file)
      project.proc_documents.attach(pdf_file)
    end

    context "when dimension attachments are non-media files" do
      before do
        project.dimension_exact.attach(html_file)
        project.proc_dimension_exact.attach(html_file)
      end

      it "rejects the non-media files" do
        expect(project).not_to be_valid
        expect(project.errors.full_messages).to eq([
          "Dimension exact is not a valid media file",
          "Proc dimension exact is not a valid media file"
        ])
      end
    end

    context "when only documents are attached" do
      before do
        project.documents.attach(pdf_file)
        project.proc_documents.attach(pdf_file)
      end

      it { is_expected.to be_valid }
    end

    context "when exact dimensions are attached" do
      before { project.dimension_exact.attach(image_150x150_file) }

      it { is_expected.to be_valid }
    end

    context "when dimensions are at the range lower bound" do
      before do
        project.dimension_range.attach(image_800x600_file)
        project.proc_dimension_range.attach(image_800x600_file)
      end

      it { is_expected.to be_valid }
    end

    context "when dimensions are at the range upper bound" do
      before do
        project.dimension_range.attach(image_1200x900_file)
        project.proc_dimension_range.attach(image_1200x900_file)
      end

      it { is_expected.to be_valid }
    end

    context "when minimum dimensions are attached" do
      before do
        project.dimension_min.attach(image_800x600_file)
        project.proc_dimension_min.attach(image_800x600_file)
      end

      it { is_expected.to be_valid }
    end

    context "when maximum dimensions are attached" do
      before do
        project.dimension_max.attach(image_1200x900_file)
        project.proc_dimension_max.attach(image_1200x900_file)
      end

      it { is_expected.to be_valid }
    end

    context "when multiple images are within dimension bounds" do
      before do
        project.dimension_images.attach([ image_800x600_file, image_1200x900_file ])
        project.proc_dimension_images.attach([ image_800x600_file, image_1200x900_file ])
      end

      it { is_expected.to be_valid }
    end

    context "when persisting updates and attaching via signed blob id" do
      before do
        project.dimension_images.attach([ image_800x600_file ])
        project.proc_dimension_images.attach([ image_800x600_file ])
        project.save!

        project.dimension_images.attach([ image_800x600_file ])
        project.proc_dimension_images.attach([ image_800x600_file ])
        project.title = "Changed"
        project.save!
        project.reload
      end

      let(:blob) { ActiveStorage::Blob.create_and_upload!(**image_800x600_file) }

      it "updates attributes and attaches via signed id" do
        expect(project.title).to eq("Changed")
        expect(project.dimension_min.attachment).to be_nil
        expect(project.proc_dimension_min.attachment).to be_nil

        project.dimension_min = blob.signed_id
        project.proc_dimension_min = blob.signed_id
        project.save!
        project.reload

        expect(project.dimension_min.attachment).not_to be_nil
        expect(project.proc_dimension_min.attachment).not_to be_nil
        expect(project.dimension_min.blob.signed_id).not_to be_nil
        expect(project.proc_dimension_min.blob.signed_id).not_to be_nil
      end
    end
  end

  describe "RatioModel aspect ratio" do
    subject(:ratio_model) { RatioModel.new(name: "Princess Leia") }

    context "with valid aspect ratios" do
      before do
        ratio_model.ratio_one.attach(image_150x150_file)
        ratio_model.proc_ratio_one.attach(image_150x150_file)
        ratio_model.ratio_many.attach([ image_600x800_file ])
        ratio_model.proc_ratio_many.attach([ image_600x800_file ])
        ratio_model.ratio_in.attach(image_150x150_file)
        ratio_model.proc_ratio_in.attach(image_150x150_file)
      end

      it "saves successfully" do
        expect { ratio_model.save! }.not_to raise_error
      end
    end

    context "when ratio_many is not portrait" do
      before do
        ratio_model.ratio_one.attach(image_150x150_file)
        ratio_model.proc_ratio_one.attach(image_150x150_file)
        ratio_model.ratio_many.attach([ image_150x150_file ])
        ratio_model.proc_ratio_many.attach([ image_150x150_file ])
        ratio_model.ratio_in.attach(image_150x150_file)
        ratio_model.proc_ratio_in.attach(image_150x150_file)
        ratio_model.save
      end

      it "rejects the non-portrait images" do
        expect(ratio_model).not_to be_valid
        expect(ratio_model.errors.full_messages).to eq([
          "Ratio many must be portrait (current file is 150x150px)",
          "Proc ratio many must be portrait (current file is 150x150px)"
        ])
      end
    end

    context "when image1 is not 16:9" do
      before do
        ratio_model.ratio_one.attach(image_150x150_file)
        ratio_model.proc_ratio_one.attach(image_150x150_file)
        ratio_model.ratio_many.attach([ image_600x800_file ])
        ratio_model.proc_ratio_many.attach([ image_600x800_file ])
        ratio_model.image1.attach(image_150x150_file)
        ratio_model.proc_image1.attach(image_150x150_file)
        ratio_model.ratio_in.attach(image_150x150_file)
        ratio_model.proc_ratio_in.attach(image_150x150_file)
      end

      it "rejects the non-16:9 images" do
        expect(ratio_model).not_to be_valid
        expect(ratio_model.errors.full_messages).to eq([
          "Image1 must be 16:9 (current file is 150x150px)",
          "Proc image1 must be 16:9 (current file is 150x150px)"
        ])
      end
    end

    context "when ratio_one is a non-media file" do
      before do
        ratio_model.ratio_one.attach(html_file)
        ratio_model.proc_ratio_one.attach(html_file)
        ratio_model.ratio_many.attach([ image_600x800_file ])
        ratio_model.proc_ratio_many.attach([ image_600x800_file ])
        ratio_model.image1.attach(image_1920x1080_file)
        ratio_model.proc_image1.attach(image_1920x1080_file)
        ratio_model.ratio_in.attach(image_150x150_file)
        ratio_model.proc_ratio_in.attach(image_150x150_file)
      end

      it "rejects the non-media files" do
        expect(ratio_model).not_to be_valid
        expect(ratio_model.errors.full_messages).to eq([
          "Ratio one is not a valid media file",
          "Proc ratio one is not a valid media file"
        ])
      end
    end

    context "when ratio_in is outside the allowed list" do
      before do
        ratio_model.ratio_one.attach(image_150x150_file)
        ratio_model.proc_ratio_one.attach(image_150x150_file)
        ratio_model.ratio_many.attach([ image_600x800_file ])
        ratio_model.proc_ratio_many.attach([ image_600x800_file ])
        ratio_model.ratio_in.attach(image_1920x1080_file)
        ratio_model.proc_ratio_in.attach(image_1920x1080_file)
      end

      it "rejects the aspect ratio and exposes details" do
        expect(ratio_model).not_to be_valid
        expect(ratio_model.errors.details).to eq(
          ratio_in: [
            {
              error: :aspect_ratio_invalid,
              validator_type: :aspect_ratio,
              filename: "image_1920x1080_file.png",
              authorized_aspect_ratios: "square, portrait",
              width: 1920,
              height: 1080
            }
          ],
          proc_ratio_in: [
            {
              error: :aspect_ratio_invalid,
              validator_type: :aspect_ratio,
              filename: "image_1920x1080_file.png",
              authorized_aspect_ratios: "square, portrait",
              width: 1920,
              height: 1080
            }
          ]
        )
      end
    end
  end
end
