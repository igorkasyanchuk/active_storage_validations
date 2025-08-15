# frozen_string_literal: true

require "test_helper"

class ActiveStorageValidations::Test < ActiveSupport::TestCase
  test "validates presence" do
    u = User.new(name: "John Smith")
    assert_not u.valid?
    assert_equal u.errors.full_messages, [ "Avatar must not be blank", "Photos can't be blank", "Proc avatar must not be blank", "Proc photos can't be blank" ]

    u = User.new(name: "John Smith")
    u.avatar.attach(image_150x150_file)
    u.proc_avatar.attach(image_150x150_file)
    assert_not u.valid?
    assert_equal u.errors.full_messages, [ "Photos can't be blank", "Proc photos can't be blank" ]

    u = User.new(name: "John Smith")
    u.photos.attach(image_150x150_file)
    u.proc_photos.attach(image_150x150_file)
    assert_not u.valid?
    assert_equal u.errors.full_messages, [ "Avatar must not be blank", "Proc avatar must not be blank" ]
  end

  test "validates content type" do
    u = User.new(name: "John Smith")
    u.avatar.attach(image_150x150_file)
    u.proc_avatar.attach(image_150x150_file)
    u.image_regex.attach(image_150x150_file)
    u.proc_image_regex.attach(image_150x150_file)
    u.photos.attach(bad_dummy_file)
    u.proc_photos.attach(bad_dummy_file)
    u.video.attach(video_file)
    assert_not u.valid?
    assert_equal u.errors.full_messages, [ 'Photos has an invalid content type (authorized content types are PNG, JPG, \\A.*/pdf\\z)', 'Proc photos has an invalid content type (authorized content types are PNG, JPG, \\A.*/pdf\\z)' ]

    u = User.new(name: "John Smith")
    u.avatar.attach(bad_dummy_file)
    u.proc_avatar.attach(bad_dummy_file)
    u.image_regex.attach(image_150x150_file)
    u.proc_image_regex.attach(image_150x150_file)
    u.photos.attach(image_150x150_file)
    u.proc_photos.attach(image_150x150_file)
    u.video.attach(video_file)
    assert_not u.valid?
    assert_equal u.errors.full_messages, [ "Avatar has an invalid content type (authorized content type is PNG)", "Proc avatar has an invalid content type (authorized content type is PNG)" ]
    assert_equal u.errors.details, avatar: [
      {
        error: :content_type_invalid,
        validator_type: :content_type,
        authorized_human_content_types: "PNG",
        content_type: "text/plain",
        human_content_type: "TXT",
        count: 1,
        filename: "apple-touch-icon.png"
      }
    ], proc_avatar: [
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

    u = User.new(name: "John Smith")
    u.avatar.attach(image_150x150_file)
    u.proc_avatar.attach(image_150x150_file)
    u.image_regex.attach(image_150x150_file)
    u.proc_image_regex.attach(image_150x150_file)
    u.photos.attach(pdf_file) # Should be handled by regex match.
    u.proc_photos.attach(pdf_file) # Should be handled by regex match.
    u.video.attach(video_file)
    assert u.valid?

    u = User.new(name: "John Smith")
    u.avatar.attach(image_150x150_file)
    u.proc_avatar.attach(image_150x150_file)
    u.image_regex.attach(bad_dummy_file)
    u.proc_image_regex.attach(bad_dummy_file)
    u.photos.attach(image_150x150_file)
    u.proc_photos.attach(image_150x150_file)
    u.video.attach(video_file)
    assert_not u.valid?
    assert_equal u.errors.full_messages, [ 'Image regex has an invalid content type (authorized content type is \\Aimage/.*\\z)', 'Proc image regex has an invalid content type (authorized content type is \\Aimage/.*\\z)' ]

    u = User.new(name: "John Smith")
    u.avatar.attach(bad_dummy_file)
    u.proc_avatar.attach(bad_dummy_file)
    u.image_regex.attach(bad_dummy_file)
    u.proc_image_regex.attach(bad_dummy_file)
    u.photos.attach(bad_dummy_file)
    u.proc_photos.attach(bad_dummy_file)
    u.video.attach(video_file)
    assert_not u.valid?
    assert_equal u.errors.full_messages, [ "Avatar has an invalid content type (authorized content type is PNG)", 'Photos has an invalid content type (authorized content types are PNG, JPG, \\A.*/pdf\\z)', 'Image regex has an invalid content type (authorized content type is \\Aimage/.*\\z)', "Proc avatar has an invalid content type (authorized content type is PNG)", 'Proc photos has an invalid content type (authorized content types are PNG, JPG, \\A.*/pdf\\z)', 'Proc image regex has an invalid content type (authorized content type is \\Aimage/.*\\z)' ]

    u = User.new(name: "Peter Griffin")
    u.avatar.attach(image_150x150_file)
    u.proc_avatar.attach(image_150x150_file)
    u.photos.attach(image_150x150_file)
    u.proc_photos.attach(image_150x150_file)
    u.conditional_image_2.attach(image_150x150_file)
    u.video.attach(video_file)
    assert u.valid?
    assert_equal u.errors.full_messages, []

    u = User.new(name: "Peter Griffin")
    u.avatar.attach(bad_dummy_file)
    u.proc_avatar.attach(bad_dummy_file)
    u.photos.attach(bad_dummy_file)
    u.proc_photos.attach(image_150x150_file)
    u.conditional_image_2.attach(bad_dummy_file)
    u.video.attach(video_file)
    assert_not u.valid?
    assert_equal u.errors.full_messages, [ "Avatar has an invalid content type (authorized content type is PNG)", "Photos has an invalid content type (authorized content types are PNG, JPG, \\A.*/pdf\\z)", "Conditional image 2 has an invalid content type (authorized content type is \\Aimage/.*\\z)", "Proc avatar has an invalid content type (authorized content type is PNG)" ]
  end

  # trying to attach webp file with PNG extension, but real content type is detected
  test "webp content type 2" do
    u = User.new(name: "John Smith")
    u.avatar.attach(webp_file)
    u.proc_avatar.attach(webp_file)
    u.image_regex.attach(webp_file)
    u.proc_image_regex.attach(webp_file)
    u.photos.attach(webp_file)
    u.proc_photos.attach(webp_file)
    assert_not u.valid?
    assert_equal u.errors.full_messages, [ "Avatar has an invalid content type (authorized content type is PNG)", 'Photos has an invalid content type (authorized content types are PNG, JPG, \\A.*/pdf\\z)', "Proc avatar has an invalid content type (authorized content type is PNG)", 'Proc photos has an invalid content type (authorized content types are PNG, JPG, \\A.*/pdf\\z)' ]
  end

  test "validates microsoft office document" do
    d = Document.new
    d.attachment.attach(docx_file)
    d.proc_attachment.attach(docx_file)
    assert d.valid?
  end

  test "validates microsoft office xlsx" do
    d = Document.new
    d.attachment.attach(xlsx_file)
    d.proc_attachment.attach(xlsx_file)
    assert d.valid?
  end

  test "validates apple office document" do
    d = Document.new
    d.attachment.attach(pages_file)
    d.proc_attachment.attach(pages_file)
    assert d.valid?
  end

  test "validates apple office numbers" do
    d = Document.new
    d.attachment.attach(numbers_file)
    d.proc_attachment.attach(numbers_file)
    assert d.valid?
  end

  test "validates archived content_type" do
    d = Document.new
    d.file.attach(tar_file)
    d.proc_file.attach(tar_file)
    assert d.valid?
  end

  test "validates maximum number of files" do
    e = Project.new(title: "Death Star")
    e.documents.attach([ pdf_file, pdf_file, pdf_file, pdf_file ])
    e.proc_documents.attach([ pdf_file, pdf_file, pdf_file, pdf_file ])
    assert_not e.valid?
    assert_equal [ "Documents total number of files must be between 1 and 3 files (there are 4 files attached)", "Proc documents total number of files must be between 1 and 3 files (there are 4 files attached)" ], e.errors.full_messages
  end

  test "validates minimum number of files" do
    e = Project.new(title: "Death Star")
    e.proc_documents.attach(pdf_file)
    assert_not e.valid?
    assert_equal [ "Documents no files attached (must have between 1 and 3 files)" ], e.errors.full_messages
  end

  test "validates number of files" do
    la = LimitAttachment.create(name: "klingon")
    la.files.attach([ pdf_file, pdf_file, pdf_file, pdf_file, pdf_file, pdf_file ])
    la.proc_files.attach([ pdf_file, pdf_file, pdf_file, pdf_file, pdf_file, pdf_file ])

    assert_not la.valid?

    assert_equal 6, la.files.count
    assert_equal 6, la.proc_files.count

    assert_equal 0, la.files_blobs.count
    assert_equal 0, la.proc_files_blobs.count

    assert_equal [ "Files too many files attached (maximum is 4 files, got 6)", "Proc files too many files attached (maximum is 4 files, got 6)" ], la.errors.full_messages

    assert_not la.valid?
    assert_equal [ "Files too many files attached (maximum is 4 files, got 6)", "Proc files too many files attached (maximum is 4 files, got 6)" ], la.errors.full_messages
  end

  test "validates number of files v2" do
    la = LimitAttachment.create(name: "klingon")
    la.files.attach([ pdf_file, pdf_file, pdf_file ])
    la.proc_files.attach([ pdf_file, pdf_file, pdf_file ])

    assert la.valid?
    assert_equal 3, la.files.count
    assert_equal 3, la.proc_files.count
    assert la.save
    la.reload

    assert_equal 3, la.files_blobs.count
    assert_equal 3, la.proc_files_blobs.count
    la.files.first.purge
    la.proc_files.first.purge

    assert la.valid?
    la.reload
    assert_equal 2, la.files_blobs.count
    assert_equal 2, la.proc_files_blobs.count
  end

  test "validates number of files v3" do
    la = LimitAttachment.create(name: "klingon")
    la.files.attach([ pdf_file, pdf_file, pdf_file, pdf_file, pdf_file ])
    la.proc_files.attach([ pdf_file, pdf_file, pdf_file, pdf_file, pdf_file ])

    assert_not la.valid?
    assert_equal 5, la.files.count
    assert_equal 5, la.proc_files.count
    assert_not la.save
  end

  test "dimensions and is image" do
    e = OnlyImage.new
    e.image.attach(html_file)
    e.proc_image.attach(html_file)
    assert_not e.valid?
    assert_equal [ "Image is not a valid media file", "Image is not a valid media file", "Image has an invalid content type (authorized content types are PNG, JPG)", "Proc image is not a valid media file", "Proc image is not a valid media file", "Proc image has an invalid content type (authorized content types are PNG, JPG)" ], e.errors.full_messages

    e = OnlyImage.new
    e.image.attach(image_1920x1080_file)
    e.proc_image.attach(image_1920x1080_file)
    e.another_image.attach(image_1920x1080_file)
    assert e.valid?

    e = OnlyImage.new
    e.image.attach(pdf_file)
    e.proc_image.attach(pdf_file)
    assert_not e.valid?
    assert e.errors.full_messages.include?("Image has an invalid content type (authorized content types are PNG, JPG)")

    e = OnlyImage.new
    e.image.attach(image_1920x1080_file)
    e.proc_image.attach(image_1920x1080_file)
    e.another_image.attach(tar_file_with_image_content_type)
    assert_not e.valid?
    assert_equal [ "Another image is not identified as a valid media file" ], e.errors.full_messages

    e = OnlyImage.new
    e.image.attach(image_1920x1080_file)
    e.proc_image.attach(image_1920x1080_file)
    e.any_image.attach(tar_file_with_image_content_type)
    assert e.valid?
  rescue Exception => ex
    puts ex.message
    puts ex.backtrace.take(20).join("\n")
    raise ex
  end

  test "dimensions with attached StringIO" do
    e = OnlyImage.new
    e.image.attach(image_string_io)
    e.proc_image.attach(image_string_io)
    e.another_image.attach(image_string_io)
    e.any_image.attach(image_string_io)
    assert e.valid?
  end

  test "dimensions test" do
    e = Project.new(title: "Death Star")
    e.dimension_exact.attach(html_file)
    e.documents.attach(pdf_file)
    e.proc_documents.attach(pdf_file)
    e.proc_dimension_exact.attach(html_file)
    assert_not e.valid?
    assert_equal [ "Dimension exact is not a valid media file", "Proc dimension exact is not a valid media file" ], e.errors.full_messages

    e = Project.new(title: "Death Star")
    e.documents.attach(pdf_file)
    e.proc_documents.attach(pdf_file)
    e.documents.attach(pdf_file)
    e.proc_documents.attach(pdf_file)
    e.valid?
    assert e.valid?

    e = Project.new(title: "Death Star")
    e.documents.attach(pdf_file)
    e.proc_documents.attach(pdf_file)
    e.dimension_exact.attach(image_150x150_file)
    # e.proc_dimension_exact.attach(image_150x150_file)
    assert e.valid?, "Dimension exact: width and height must be equal to 150 x 150 pixels."

    e = Project.new(title: "Death Star")
    e.documents.attach(pdf_file)
    e.proc_documents.attach(pdf_file)
    e.dimension_range.attach(image_800x600_file)
    e.proc_dimension_range.attach(image_800x600_file)
    assert e.valid?, "Dimension range: width and height must be greater than or equal to 800 x 600 pixels."

    e = Project.new(title: "Death Star")
    e.documents.attach(pdf_file)
    e.proc_documents.attach(pdf_file)
    e.dimension_range.attach(image_1200x900_file)
    e.proc_dimension_range.attach(image_1200x900_file)
    assert e.valid?, "Dimension range: width and height must be less than or equal to 1200 x 900 pixels."

    e = Project.new(title: "Death Star")
    e.documents.attach(pdf_file)
    e.proc_documents.attach(pdf_file)
    e.dimension_min.attach(image_800x600_file)
    e.proc_dimension_min.attach(image_800x600_file)
    assert e.valid?, "Dimension min: width and height must be greater than or equal to 800 x 600 pixels."

    e = Project.new(title: "Death Star")
    e.documents.attach(pdf_file)
    e.proc_documents.attach(pdf_file)
    e.dimension_max.attach(image_1200x900_file)
    e.proc_dimension_max.attach(image_1200x900_file)
    assert e.valid?, "Dimension max: width and height must be greater than or equal to 1200 x 900 pixel."

    e = Project.new(title: "Death Star")
    e.documents.attach(pdf_file)
    e.proc_documents.attach(pdf_file)
    e.dimension_images.attach([ image_800x600_file, image_1200x900_file ])
    e.proc_dimension_images.attach([ image_800x600_file, image_1200x900_file ])
    assert e.valid?, "Dimension many: width and height must be between or equal to 800 x 600 and 1200 x 900 pixel."

    e = Project.new(title: "Death Star")
    e.documents.attach(pdf_file)
    e.proc_documents.attach(pdf_file)
    e.dimension_images.attach([ image_800x600_file ])
    e.proc_dimension_images.attach([ image_800x600_file ])
    e.save!
    e.dimension_images.attach([ image_800x600_file ])
    e.proc_dimension_images.attach([ image_800x600_file ])

    e.title = "Changed"
    e.save!
    e.reload
    assert e.title, "Changed"

    assert_nil e.dimension_min.attachment
    assert_nil e.proc_dimension_min.attachment
    blob = ActiveStorage::Blob.create_and_upload!(**image_800x600_file)
    e.dimension_min = blob.signed_id
    e.proc_dimension_min = blob.signed_id
    e.save!
    e.reload
    assert_not_nil e.dimension_min.attachment
    assert_not_nil e.proc_dimension_min.attachment
    assert_not_nil e.dimension_min.blob.signed_id
    assert_not_nil e.proc_dimension_min.blob.signed_id
  rescue Exception => ex
    puts ex.message
    puts ex.backtrace.join("\n")
    raise ex
  end

  test "all dimension validation errors are shown together" do
    # image dimensions are lower than the specified range
    project = Project.new(title: "Death Star")
    project.dimension_range.attach(image_700x500_file)
    assert_not project.valid?
    assert_includes project.errors.full_messages, "Dimension range width is not included between 800 and 1200 pixel"
    assert_includes project.errors.full_messages, "Dimension range height is not included between 600 and 900 pixel"

    project = Project.new(title: "Death Star")
    project.dimension_images.attach([ image_700x500_file ])
    assert_not project.valid?
    assert_includes project.errors.full_messages, "Dimension images width must be greater than or equal to 800 pixel"
    assert_includes project.errors.full_messages, "Dimension images height must be greater than or equal to 600 pixel"

    # image dimensions are greater than the specified range
    project = Project.new(title: "Death Star")
    project.dimension_range.attach(image_1300x1000_file)
    assert_not project.valid?
    assert_includes project.errors.full_messages, "Dimension range width is not included between 800 and 1200 pixel"
    assert_includes project.errors.full_messages, "Dimension range height is not included between 600 and 900 pixel"

    project = Project.new(title: "Death Star")
    project.dimension_images.attach([ image_1300x1000_file ])
    assert_not project.valid?
    assert_includes project.errors.full_messages, "Dimension images width must be less than or equal to 1200 pixel"
    assert_includes project.errors.full_messages, "Dimension images height must be less than or equal to 900 pixel"
  rescue Exception => ex
    puts ex.message
    puts ex.backtrace.join("\n")
    raise ex
  end

  test "aspect ratio validation" do
    e = RatioModel.new(name: "Princess Leia")
    e.ratio_one.attach(image_150x150_file)
    e.proc_ratio_one.attach(image_150x150_file)
    e.ratio_many.attach([ image_600x800_file ])
    e.proc_ratio_many.attach([ image_600x800_file ])
    e.ratio_in.attach(image_150x150_file)
    e.proc_ratio_in.attach(image_150x150_file)
    e.save!

    e = RatioModel.new(name: "Princess Leia")
    e.ratio_one.attach(image_150x150_file)
    e.proc_ratio_one.attach(image_150x150_file)
    e.ratio_many.attach([ image_150x150_file ])
    e.proc_ratio_many.attach([ image_150x150_file ])
    e.ratio_in.attach(image_150x150_file)
    e.proc_ratio_in.attach(image_150x150_file)
    e.save
    assert_not e.valid?
    assert_equal [ "Ratio many must be portrait (current file is 150x150px)", "Proc ratio many must be portrait (current file is 150x150px)" ], e.errors.full_messages

    e = RatioModel.new(name: "Princess Leia")
    e.ratio_one.attach(image_150x150_file)
    e.proc_ratio_one.attach(image_150x150_file)
    e.ratio_many.attach([ image_600x800_file ])
    e.proc_ratio_many.attach([ image_600x800_file ])
    e.image1.attach(image_150x150_file)
    e.proc_image1.attach(image_150x150_file)
    e.ratio_in.attach(image_150x150_file)
    e.proc_ratio_in.attach(image_150x150_file)
    assert_not e.valid?
    assert_equal [ "Image1 must be 16:9 (current file is 150x150px)", "Proc image1 must be 16:9 (current file is 150x150px)" ], e.errors.full_messages

    e = RatioModel.new(name: "Princess Leia")
    e.ratio_one.attach(html_file)
    e.proc_ratio_one.attach(html_file)
    e.ratio_many.attach([ image_600x800_file ])
    e.proc_ratio_many.attach([ image_600x800_file ])
    e.image1.attach(image_1920x1080_file)
    e.proc_image1.attach(image_1920x1080_file)
    e.ratio_in.attach(image_150x150_file)
    e.proc_ratio_in.attach(image_150x150_file)
    assert_not e.valid?
    assert_equal [ "Ratio one is not a valid media file", "Proc ratio one is not a valid media file" ], e.errors.full_messages

    e = RatioModel.new(name: "Princess Leia")
    e.ratio_one.attach(image_150x150_file)
    e.proc_ratio_one.attach(image_150x150_file)
    e.ratio_many.attach([ image_600x800_file ])
    e.proc_ratio_many.attach([ image_600x800_file ])
    e.ratio_in.attach(image_1920x1080_file)
    e.proc_ratio_in.attach(image_1920x1080_file)
    assert_not e.valid?
    assert_equal(
      {
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
      },
      e.errors.details
    )
  end
end
