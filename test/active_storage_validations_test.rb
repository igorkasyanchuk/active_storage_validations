# frozen_string_literal: true

require 'test_helper'

class ActiveStorageValidations::Test < ActiveSupport::TestCase
  test 'truth' do
    assert_kind_of Module, ActiveStorageValidations
  end

  test 'validates presence' do
    u = User.new(name: 'John Smith')
    assert !u.valid?
    assert_equal u.errors.full_messages, ["Avatar can't be blank", "Photos can't be blank"]

    u = User.new(name: 'John Smith')
    u.avatar.attach(dummy_file)
    assert !u.valid?
    assert_equal u.errors.full_messages, ["Photos can't be blank"]

    u = User.new(name: 'John Smith')
    u.photos.attach(dummy_file)
    assert !u.valid?
    assert_equal u.errors.full_messages, ["Avatar can't be blank"]
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

    la = LimitAttachment.create(name: 'klingon')
    (0..5).each do
      la.files.attach(pdf_file)
    end
    assert !la.valid?
    assert_equal 4, la.files_blobs.count
    assert_equal ['Files total number is out of range'], la.errors.full_messages

    la.files_blobs.first.purge
    la.files_blobs.first.purge
    la.files_blobs.first.purge
    la.files_blobs.first.purge

    assert !la.valid?
    assert_equal ['Files total number is out of range'], la.errors.full_messages
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

    e.title = "Changed"
    e.save!
    e.reload
    assert e.title, "Changed"

    assert_nil e.dimension_min.attachment
    blob = ActiveStorage::Blob.create_after_upload!(image_800x600_file)
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
    assert_equal e.errors.full_messages, ["Ratio many doesn't contain a portrait image"]

    e = RatioModel.new(name: 'Princess Leia')
    e.ratio_one.attach(image_150x150_file)
    e.ratio_many.attach([image_600x800_file])
    e.image1.attach(image_150x150_file)
    assert !e.valid?
    assert_equal e.errors.full_messages, ["Image1 doesn't contain aspect ratio of 16x9"]

    e = RatioModel.new(name: 'Princess Leia')
    e.ratio_one.attach(html_file)
    e.ratio_many.attach([image_600x800_file])
    e.image1.attach(image_1920x1080_file)
    assert !e.valid?
    assert_equal e.errors.full_messages, ["Ratio one is not a valid image"]
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
