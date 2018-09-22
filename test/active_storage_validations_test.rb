require 'test_helper'

class ActiveStorageValidations::Test < ActiveSupport::TestCase
  test "truth" do
    assert_kind_of Module, ActiveStorageValidations
  end

  test "validates" do
    u = build_user
    assert !u.valid?
    assert_equal u.errors.full_messages, ["Avatar can't be blank", "Photos can't be blank"]

    u = build_user
    u.avatar.attach(good_file)
    assert !u.valid?
    assert_equal u.errors.full_messages, ["Photos can't be blank"]

    u = build_user
    u.photos.attach(good_file)
    assert !u.valid?
    assert_equal u.errors.full_messages, ["Avatar can't be blank"]

    u = build_user
    u.avatar.attach(good_file)
    u.photos.attach(bad_file)
    assert !u.valid?
    assert_equal u.errors.full_messages, ["Photos does not have an authorized content type, authorized content types : [\"image/png\", \"image/jpg\"]"]

    u = build_user
    u.avatar.attach(bad_file)
    u.photos.attach(good_file)
    assert !u.valid?
    assert_equal u.errors.full_messages, ["Avatar does not have an authorized content type, authorized content types : [\"image/png\"]"]

    u = build_user
    u.avatar.attach(bad_file)
    u.photos.attach(bad_file)
    assert !u.valid?
    assert_equal u.errors.full_messages, ["Avatar does not have an authorized content type, authorized content types : [\"image/png\"]", "Photos does not have an authorized content type, authorized content types : [\"image/png\", \"image/jpg\"]"]
  end
end

def file
  File.open(Rails.root.join('public', 'apple-touch-icon.png'))
end

def build_user
  User.new(name: 'John Smith')
end

def good_file
  { io: file, filename: 'attachment.png', content_type: 'image/png' }
end

def bad_file
  { io: file, filename: 'attachment.png', content_type: 'text/plain' }
end
