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
    assert_equal u.errors.full_messages, ["Photos has an invalid content type"]

    u = build_user
    u.avatar.attach(bad_dummy_file)
    u.photos.attach(good_dummy_file)
    assert !u.valid?
    assert_equal u.errors.full_messages, ["Avatar has an invalid content type"]

    u = build_user
    u.avatar.attach(bad_dummy_file)
    u.photos.attach(bad_dummy_file)
    assert !u.valid?
    assert_equal u.errors.full_messages, ["Avatar has an invalid content type", "Photos has an invalid content type"]

    e = build_project
    e.preview.attach(good_big_file)
    e.small_file.attach(good_big_file)
    e.attachment.attach(good_pdf_file)
    e.documents.attach(good_dummy_file)
    assert !e.valid?
    assert_equal e.errors.full_messages, ["Small file size 1.6 KB is not between required range"]

    # validates :documents, limit: { min: 1, max: 3 }
    e = build_project
    e.preview.attach(good_big_file)
    e.small_file.attach(good_dummy_file)
    e.attachment.attach(good_pdf_file)
    assert !e.valid?
    assert_equal e.errors.full_messages, ["Documents total number is out of range"]

    e = build_project
    e.preview.attach(good_big_file)
    e.small_file.attach(good_dummy_file)
    e.attachment.attach(good_pdf_file)
    e.documents.attach(good_pdf_file)
    e.documents.attach(good_pdf_file)
    e.documents.attach(good_pdf_file)
    e.documents.attach(good_pdf_file)
    assert !e.valid?
    assert_equal e.errors.full_messages, ["Documents total number is out of range"]

    e = build_project
    e.preview.attach(good_big_file)
    e.small_file.attach(good_dummy_file)
    e.attachment.attach(good_pdf_file)
    e.documents.attach(good_pdf_file)
    e.documents.attach(good_pdf_file)
    assert e.valid?
  end
end

def build_user; User.new(name: 'John Smith'); end
def build_project; Project.new(title: 'Death Star'); end

def dummy_file; File.open(Rails.root.join('public', 'apple-touch-icon.png')); end
def big_file; File.open(Rails.root.join('public', '500.html')); end
def pdf_file; File.open(Rails.root.join('public', 'pdf.pdf')); end

def good_dummy_file; { io: dummy_file, filename: 'attachment.png', content_type: 'image/png' }; end
def good_big_file; { io: big_file, filename: 'attachment.png', content_type: 'image/png' }; end
def good_pdf_file; { io: pdf_file, filename: 'attachment.pdf', content_type: 'application/pdf' }; end
def bad_dummy_file; { io: dummy_file, filename: 'attachment.png', content_type: 'text/plain' }; end