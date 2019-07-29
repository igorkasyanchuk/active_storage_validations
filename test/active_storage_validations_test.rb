# frozen_string_literal: true

require 'test_helper'

class ActiveStorageValidations::Test < ActiveSupport::TestCase
  test 'truth' do
    assert_kind_of Module, ActiveStorageValidations
  end

  test 'validates' do
    u = build_user
    assert !u.valid?
    assert_equal u.errors.full_messages, ["Avatar can't be blank", "Photos can't be blank"]

    u = build_user
    u.avatar.attach(good_dummy_file)
    assert !u.valid?
    assert_equal u.errors.full_messages, ["Photos can't be blank"]

    u = build_user
    u.photos.attach(good_dummy_file)
    assert !u.valid?
    assert_equal u.errors.full_messages, ["Avatar can't be blank"]

    u = build_user
    u.avatar.attach(good_dummy_file)
    u.photos.attach(bad_dummy_file)
    assert !u.valid?
    assert_equal u.errors.full_messages, ['Photos has an invalid content type']

    u = build_user
    u.avatar.attach(bad_dummy_file)
    u.photos.attach(good_dummy_file)
    assert !u.valid?
    assert_equal u.errors.full_messages, ['Avatar has an invalid content type']

    u = build_user
    u.avatar.attach(bad_dummy_file)
    u.photos.attach(bad_dummy_file)
    assert !u.valid?
    assert_equal u.errors.full_messages, ['Avatar has an invalid content type', 'Photos has an invalid content type']

    e = build_project
    e.preview.attach(good_big_file)
    e.small_file.attach(good_big_file)
    e.attachment.attach(good_pdf_file)
    assert !e.valid?
    assert_equal e.errors.full_messages, ['Small file size 1.6 KB is not between required range']

    e = build_project
    e.preview.attach(good_big_file)
    e.small_file.attach(good_dummy_file)
    e.attachment.attach(good_pdf_file)
    e.documents.attach(good_pdf_file)
    e.documents.attach(good_pdf_file)
    e.documents.attach(good_pdf_file)
    e.documents.attach(good_pdf_file)
    assert !e.valid?
    assert_equal e.errors.full_messages, ['Documents total number is out of range']

    e = build_project
    e.preview.attach(good_big_file)
    e.small_file.attach(good_dummy_file)
    e.attachment.attach(good_pdf_file)
    e.dimension_exact.attach(good_pdf_file)
    assert !e.valid?
    assert_equal e.errors.full_messages, ['Dimension exact is not a valid image']

    e = build_project
    e.preview.attach(good_big_file)
    e.small_file.attach(good_dummy_file)
    e.attachment.attach(good_pdf_file)
    e.documents.attach(good_pdf_file)
    e.documents.attach(good_pdf_file)
    assert e.valid?

    e = build_project
    e.preview.attach(good_big_file)
    e.small_file.attach(good_dummy_file)
    e.attachment.attach(good_pdf_file)
    e.dimension_exact.attach(good_image_150x150_file)
    assert e.valid?, 'Dimension exact: width and height must be equal to 150 x 150 pixel.'

    e = build_project
    e.preview.attach(good_big_file)
    e.small_file.attach(good_dummy_file)
    e.attachment.attach(good_pdf_file)
    e.dimension_range.attach(good_image_800x600_file)
    assert e.valid?, 'Dimension range: width and height must be greater than or equal to 800 x 600 pixel.'

    e = build_project
    e.preview.attach(good_big_file)
    e.small_file.attach(good_dummy_file)
    e.attachment.attach(good_pdf_file)
    e.dimension_range.attach(good_image_1200x900_file)
    assert e.valid?, 'Dimension range: width and height must be less than or equal to 1200 x 900 pixel.'

    e = build_project
    e.preview.attach(good_big_file)
    e.small_file.attach(good_dummy_file)
    e.attachment.attach(good_pdf_file)
    e.dimension_min.attach(good_image_800x600_file)
    assert e.valid?, 'Dimension min: width and height must be greater than or equal to 800 x 600 pixel.'

    e = build_project
    e.preview.attach(good_big_file)
    e.small_file.attach(good_dummy_file)
    e.attachment.attach(good_pdf_file)
    e.dimension_max.attach(good_image_1200x900_file)
    assert e.valid?, 'Dimension max: width and height must be greater than or equal to 1200 x 900 pixel.'

    e = build_project
    e.preview.attach(good_big_file)
    e.small_file.attach(good_dummy_file)
    e.attachment.attach(good_pdf_file)
    e.dimension_images.attach([good_image_800x600_file, good_image_1200x900_file])
    assert e.valid?, 'Dimension many: width and height must be between or equal to 800 x 600 and 1200 x 900 pixel.'

    e = build_project
    e.preview.attach(good_big_file)
    e.small_file.attach(good_dummy_file)
    e.attachment.attach(good_pdf_file)
    e.dimension_images.attach([good_image_800x600_file])
    e.save!

    e.title = "Changed"
    e.save!
    e.reload
    assert e.title, "Changed"

    assert_nil e.dimension_min.attachment
    blob = ActiveStorage::Blob.create_after_upload!(good_image_800x600_file)
    e.dimension_min = blob.signed_id
    e.save!
    e.reload
    assert_not_nil e.dimension_min.attachment
    assert_not_nil e.dimension_min.blob.signed_id
  rescue Exception => ex
    puts ex.message
    puts ex.backtrace.take(20).join("\n")
    raise ex
  end

  test 'aspect ratio validation' do
    # e = build_ratio_model
    # e.ratio_one.attach(good_image_150x150_file)
    # e.ratio_many.attach([good_image_600x800_file])
    # e.save!

    e = build_ratio_model
    e.ratio_one.attach(good_image_150x150_file)
    e.ratio_many.attach([good_image_150x150_file])
    e.save
    assert !e.valid?
    assert_equal e.errors.full_messages, ["Ratio many doesn't contain a portrait image"]

    e = build_ratio_model
    e.ratio_one.attach(good_image_150x150_file)
    e.ratio_many.attach([good_image_600x800_file])
    e.image1.attach(good_image_150x150_file)
    assert !e.valid?
    assert_equal e.errors.full_messages, ["Image1 doesn't contain aspect ratio of 16x9"]

    e = build_ratio_model
    e.ratio_one.attach(good_pdf_file)
    e.ratio_many.attach([good_image_600x800_file])
    e.image1.attach(good_image_1920x1080_file)
    assert !e.valid?
    assert_equal e.errors.full_messages, ["Ratio one is not a valid image"]
  end
end

def build_user
  User.new(name: 'John Smith')
end

def build_project
  Project.new(title: 'Death Star')
end

def build_ratio_model
  RatioModel.new(name: 'Princess Leia')
end

def dummy_file
  File.open(Rails.root.join('public', 'apple-touch-icon.png'))
end

def big_file
  File.open(Rails.root.join('public', '500.html'))
end

def pdf_file
  File.open(Rails.root.join('public', 'pdf.pdf'))
end

def image_150x150_file
  File.open(Rails.root.join('public', 'image_150x150.png'))
end

def image_800x600_file
  File.open(Rails.root.join('public', 'image_800x600.png'))
end

def image_600x800_file
  File.open(Rails.root.join('public', 'image_600x800.png'))
end

def image_1200x900_file
  File.open(Rails.root.join('public', 'image_1200x900.png'))
end

def image_1920x1080_file
  File.open(Rails.root.join('public', 'image_1920x1080.png'))
end

def good_dummy_file
  { io: dummy_file, filename: 'attachment.png', content_type: 'image/png' }
end

def good_big_file
  { io: big_file, filename: 'attachment.png', content_type: 'image/png' }
end

def good_pdf_file
  { io: pdf_file, filename: 'attachment.pdf', content_type: 'application/pdf' }
end

def bad_dummy_file
  { io: dummy_file, filename: 'attachment.png', content_type: 'text/plain' }
end

def good_image_150x150_file
  { io: image_150x150_file, filename: 'attachment.png', content_type: 'image/png' }
end

def good_image_800x600_file
  { io: image_800x600_file, filename: 'attachment.png', content_type: 'image/png' }
end

def good_image_600x800_file
  { io: image_600x800_file, filename: 'attachment.png', content_type: 'image/png' }
end

def good_image_1200x900_file
  { io: image_1200x900_file, filename: 'attachment.png', content_type: 'image/png' }
end

def good_image_1920x1080_file
  { io: image_1920x1080_file, filename: 'attachment.png', content_type: 'image/png' }
end
