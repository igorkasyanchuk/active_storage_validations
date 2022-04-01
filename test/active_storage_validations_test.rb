# frozen_string_literal: true

# Run tests using:
# BUNDLE_GEMFILE=gemfiles/rails_5_2.gemfile bundle exec rake test
# BUNDLE_GEMFILE=gemfiles/rails_6_0.gemfile bundle exec rake test

require 'test_helper'

class ActiveStorageValidations::Test < ActiveSupport::TestCase
  test 'truth' do
    assert_kind_of Module, ActiveStorageValidations
  end

  test 'validates presence' do
    u = User.new(name: 'John Smith')
    assert !u.valid?
    assert_equal u.errors.full_messages, ["Avatar must not be blank", "Photos can't be blank"]

    u = User.new(name: 'John Smith')
    u.avatar.attach(dummy_file)
    assert !u.valid?
    assert_equal u.errors.full_messages, ["Photos can't be blank"]

    u = User.new(name: 'John Smith')
    u.photos.attach(dummy_file)
    assert !u.valid?
    assert_equal u.errors.full_messages, ["Avatar must not be blank"]
  end

  test 'validates content type' do
    u = User.new(name: 'John Smith')
    u.avatar.attach(dummy_file)
    u.image_regex.attach(dummy_file)
    u.photos.attach(bad_dummy_file)
    assert !u.valid?
    assert_equal u.errors.full_messages, ['Photos has an invalid content type']

    u = User.new(name: 'John Smith')
    u.avatar.attach(bad_dummy_file)
    u.image_regex.attach(dummy_file)
    u.photos.attach(dummy_file)
    assert !u.valid?
    assert_equal u.errors.full_messages, ['Avatar has an invalid content type']
    assert_equal u.errors.details, avatar: [
      {
        error: :content_type_invalid,
        authorized_types: 'PNG',
        content_type: 'text/plain'
      }
    ]

    u = User.new(name: 'John Smith')
    u.avatar.attach(dummy_file)
    u.image_regex.attach(dummy_file)
    u.photos.attach(pdf_file) # Should be handled by regex match.
    assert u.valid?

    u = User.new(name: 'John Smith')
    u.avatar.attach(dummy_file)
    u.image_regex.attach(bad_dummy_file)
    u.photos.attach(dummy_file)
    assert !u.valid?
    assert_equal u.errors.full_messages, ['Image regex has an invalid content type']

    u = User.new(name: 'John Smith')
    u.avatar.attach(bad_dummy_file)
    u.image_regex.attach(bad_dummy_file)
    u.photos.attach(bad_dummy_file)
    assert !u.valid?
    assert_equal u.errors.full_messages, ['Avatar has an invalid content type', 'Photos has an invalid content type', 'Image regex has an invalid content type']
  end

  # reads content type from file, not from webp_file_wrong method
  test 'webp content type 1' do
    u = User.new(name: 'John Smith')
    u.avatar.attach(webp_file_wrong)
    u.image_regex.attach(webp_file_wrong)
    u.photos.attach(webp_file_wrong)
    assert !u.valid?
    assert_equal u.errors.full_messages, ['Avatar has an invalid content type', 'Photos has an invalid content type']
  end

  # trying to attach webp file with PNG extension, but real content type is detected
  test 'webp content type 2' do
    u = User.new(name: 'John Smith')
    u.avatar.attach(webp_file)
    u.image_regex.attach(webp_file)
    u.photos.attach(webp_file)
    assert !u.valid?
    assert_equal u.errors.full_messages, ['Avatar has an invalid content type', 'Photos has an invalid content type']
  end

  test 'validates microsoft office document' do
    d = Document.new
    d.attachment.attach(docx_file)
    assert d.valid?
  end

  test 'validates microsoft office sheet' do
    d = Document.new
    d.attachment.attach(sheet_file)
    assert d.valid?
  end

  test 'validates apple office document' do
    d = Document.new
    d.attachment.attach(pages_file)
    assert d.valid?
  end

  test 'validates apple office sheet' do
    d = Document.new
    d.attachment.attach(numbers_file)
    assert d.valid?
  end

  test 'validates archived content_type' do
    d = Document.new
    d.file.attach(tar_file)
    assert d.valid?
  end

  test 'validates size' do
    e = Project.new(title: 'Death Star')
    e.preview.attach(big_file)
    e.small_file.attach(big_file)
    e.attachment.attach(pdf_file)
    assert !e.valid?
    assert_equal e.errors.full_messages, ['Small file size 1.6 KB is not between required range']
  end

  test 'validates number of files' do
    e = Project.new(title: 'Death Star')
    e.preview.attach(big_file)
    e.small_file.attach(dummy_file)
    e.attachment.attach(pdf_file)
    e.documents.attach(pdf_file)
    e.documents.attach(pdf_file)
    e.documents.attach(pdf_file)
    e.documents.attach(pdf_file)
    assert !e.valid?
    assert_equal e.errors.full_messages, ['Documents total number is out of range']
  end

  test 'validates number of files for Rails 6' do
    la = LimitAttachment.create(name: 'klingon')
    la.files.attach([pdf_file, pdf_file, pdf_file, pdf_file, pdf_file, pdf_file])

    assert !la.valid?

    assert_equal 6, la.files.count

    if Rails.gem_version < Gem::Version.new('6.0.0')
      assert_equal 6, la.files_blobs.count
    else
      assert_equal 0, la.files_blobs.count
    end

    assert_equal ['Files total number is out of range'], la.errors.full_messages

    if Rails.gem_version < Gem::Version.new('6.0.0')
      la.files.first.purge
      la.files.first.purge
      la.files.first.purge
      la.files.first.purge
    end

    assert !la.valid?
    assert_equal ['Files total number is out of range'], la.errors.full_messages
  end

  test 'validates number of files v2' do
    la = LimitAttachment.create(name: 'klingon')
    la.files.attach([pdf_file, pdf_file, pdf_file])

    assert la.valid?
    assert_equal 3, la.files.count
    assert la.save
    la.reload

    assert_equal 3, la.files_blobs.count
    la.files.first.purge

    assert la.valid?
    la.reload
    assert_equal 2, la.files_blobs.count
  end

  test 'validates number of files v3' do
    la = LimitAttachment.create(name: 'klingon')
    la.files.attach([pdf_file, pdf_file, pdf_file, pdf_file, pdf_file])

    assert !la.valid?
    assert_equal 5, la.files.count
    assert !la.save
  end

  test 'dimensions and is image' do
    e = OnlyImage.new
    e.image.attach(html_file)
    assert !e.valid?
    assert_equal e.errors.full_messages, ["Image is not a valid image", "Image has an invalid content type"]

    e = OnlyImage.new
    e.image.attach(image_1920x1080_file)
    assert e.valid?

    e = OnlyImage.new
    e.image.attach(pdf_file)
    assert !e.valid?
    assert e.errors.full_messages.include?("Image has an invalid content type")
  rescue Exception => ex
    puts ex.message
    puts ex.backtrace.take(20).join("\n")
    raise ex
  end

  test 'dimensions test' do
    e = Project.new(title: 'Death Star')
    e.preview.attach(big_file)
    e.small_file.attach(dummy_file)
    e.attachment.attach(pdf_file)
    e.dimension_exact.attach(html_file)
    assert !e.valid?
    assert_equal e.errors.full_messages, ['Dimension exact is not a valid image']

    e = Project.new(title: 'Death Star')
    e.preview.attach(big_file)
    e.small_file.attach(dummy_file)
    e.attachment.attach(pdf_file)
    e.documents.attach(pdf_file)
    e.documents.attach(pdf_file)
    e.valid?
    assert e.valid?

    e = Project.new(title: 'Death Star')
    e.preview.attach(big_file)
    e.small_file.attach(dummy_file)
    e.attachment.attach(pdf_file)
    e.dimension_exact.attach(image_150x150_file)
    assert e.valid?, 'Dimension exact: width and height must be equal to 150 x 150 pixel.'

    e = Project.new(title: 'Death Star')
    e.preview.attach(big_file)
    e.small_file.attach(dummy_file)
    e.attachment.attach(pdf_file)
    e.dimension_range.attach(image_800x600_file)
    assert e.valid?, 'Dimension range: width and height must be greater than or equal to 800 x 600 pixel.'

    e = Project.new(title: 'Death Star')
    e.preview.attach(big_file)
    e.small_file.attach(dummy_file)
    e.attachment.attach(pdf_file)
    e.dimension_range.attach(image_1200x900_file)
    assert e.valid?, 'Dimension range: width and height must be less than or equal to 1200 x 900 pixel.'

    e = Project.new(title: 'Death Star')
    e.preview.attach(big_file)
    e.small_file.attach(dummy_file)
    e.attachment.attach(pdf_file)
    e.dimension_min.attach(image_800x600_file)
    assert e.valid?, 'Dimension min: width and height must be greater than or equal to 800 x 600 pixel.'

    e = Project.new(title: 'Death Star')
    e.preview.attach(big_file)
    e.small_file.attach(dummy_file)
    e.attachment.attach(pdf_file)
    e.dimension_max.attach(image_1200x900_file)
    assert e.valid?, 'Dimension max: width and height must be greater than or equal to 1200 x 900 pixel.'

    e = Project.new(title: 'Death Star')
    e.preview.attach(big_file)
    e.small_file.attach(dummy_file)
    e.attachment.attach(pdf_file)
    e.dimension_images.attach([image_800x600_file, image_1200x900_file])
    assert e.valid?, 'Dimension many: width and height must be between or equal to 800 x 600 and 1200 x 900 pixel.'

    e = Project.new(title: 'Death Star')
    e.preview.attach(big_file)
    e.small_file.attach(dummy_file)
    e.attachment.attach(pdf_file)
    e.dimension_images.attach([image_800x600_file])
    e.save!
    e.dimension_images.attach([image_800x600_file])

    e.title = "Changed"
    e.save!
    e.reload
    assert e.title, "Changed"

    assert_nil e.dimension_min.attachment
    blob =
      if Rails.gem_version >= Gem::Version.new('6.1.0')
        ActiveStorage::Blob.create_and_upload!(**image_800x600_file)
      else
        ActiveStorage::Blob.create_after_upload!(**image_800x600_file)
      end
    e.dimension_min = blob.signed_id
    e.save!
    e.reload
    assert_not_nil e.dimension_min.attachment
    assert_not_nil e.dimension_min.blob.signed_id
  rescue Exception => ex
    puts ex.message
    puts ex.backtrace.join("\n")
    raise ex
  end

  test 'aspect ratio validation' do
    e = RatioModel.new(name: 'Princess Leia')
    e.ratio_one.attach(image_150x150_file)
    e.ratio_many.attach([image_600x800_file])
    e.save!

    e = RatioModel.new(name: 'Princess Leia')
    e.ratio_one.attach(image_150x150_file)
    e.ratio_many.attach([image_150x150_file])
    e.save
    assert !e.valid?
    assert_equal e.errors.full_messages, ["Ratio many must be a portrait image"]

    e = RatioModel.new(name: 'Princess Leia')
    e.ratio_one.attach(image_150x150_file)
    e.ratio_many.attach([image_600x800_file])
    e.image1.attach(image_150x150_file)
    assert !e.valid?
    assert_equal e.errors.full_messages, ["Image1 must have an aspect ratio of 16x9"]

    e = RatioModel.new(name: 'Princess Leia')
    e.ratio_one.attach(html_file)
    e.ratio_many.attach([image_600x800_file])
    e.image1.attach(image_1920x1080_file)
    assert !e.valid?
    assert_equal e.errors.full_messages, ["Ratio one is not a valid image"]

    e = RatioModel.new(name: 'Princess Leia')
    e.ratio_one.attach(io_file)
    e.ratio_many.attach([io_file])
    assert !e.valid?
    assert_equal e.errors.full_messages, ["Ratio one is not a valid image", "Ratio many is not a valid image"]
  end
end

def dummy_file
  { io: File.open(Rails.root.join('public', 'apple-touch-icon.png')), filename: 'dummy_file.png', content_type: 'image/png' }
end

def big_file
  { io: File.open(Rails.root.join('public', '500.html')), filename: 'big_file.png', content_type: 'image/png' }
end

def pdf_file
  { io: File.open(Rails.root.join('public', 'pdf.pdf')), filename: 'pdf_file.pdf', content_type: 'application/pdf' }
end

def bad_dummy_file
  { io: File.open(Rails.root.join('public', 'apple-touch-icon.png')), filename: 'bad_dummy_file.png', content_type: 'text/plain' }
end

def image_150x150_file
  { io: File.open(Rails.root.join('public', 'image_150x150.png')), filename: 'image_150x150_file.png', content_type: 'image/png' }
end

def image_800x600_file
  { io: File.open(Rails.root.join('public', 'image_800x600.png')), filename: 'image_800x600_file.png', content_type: 'image/png' }
end

def image_600x800_file
  { io: File.open(Rails.root.join('public', 'image_600x800.png')), filename: 'image_600x800_file.png', content_type: 'image/png' }
end

def image_1200x900_file
  { io: File.open(Rails.root.join('public', 'image_1200x900.png')), filename: 'image_1200x900_file.png', content_type: 'image/png' }
end

def image_1920x1080_file
  { io: File.open(Rails.root.join('public', 'image_1920x1080.png')), filename: 'image_1920x1080_file.png', content_type: 'image/png' }
end

def html_file
  { io: File.open(Rails.root.join('public', '500.html')), filename: 'html_file.html', content_type: 'text/html' }
end

def webp_file
  { io: File.open(Rails.root.join('public', '1_sm_webp.png')), filename: '1_sm_webp.png', content_type: 'image/webp' }
end

def webp_file_wrong
  { io: File.open(Rails.root.join('public', '1_sm_webp.png')), filename: '1_sm_webp.png', content_type: 'image/png' }
end

def docx_file
  { io: File.open(Rails.root.join('public', 'example.docx')), filename: 'example.docx', content_type: 'application/vnd.openxmlformats-officedocument.wordprocessingml.document' }
end

def sheet_file
  { io: File.open(Rails.root.join('public', 'example.xlsx')), filename: 'example.xlsx', content_type: 'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet' }
end

def pages_file
  { io: File.open(Rails.root.join('public', 'example.pages')), filename: 'example.pages', content_type: 'application/vnd.apple.pages' }
end

def numbers_file
  { io: File.open(Rails.root.join('public', 'example.numbers')), filename: 'example.numbers', content_type: 'application/vnd.apple.numbers' }
end

def tar_file
  { io: File.open(Rails.root.join('public', '404.html.tar')), filename: '404.html.tar', content_type: 'application/x-tar' }
end

def io_file
  { io: StringIO.new("binary"), filename: 'dummy_file.png', content_type: 'image/png' }
end