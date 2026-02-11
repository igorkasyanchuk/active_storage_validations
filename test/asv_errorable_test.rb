# frozen_string_literal: true

require "test_helper"

describe ActiveStorageValidations::AttachedValidator do
  let(:validator) { ActiveStorageValidations::AttachedValidator.new(attributes: [ :avatar ]) }
  let(:user) { User.new(name: "ASV Errorable") }
  let(:file) { nil }
  let(:error_options) { validator.initialize_error_options({}, file) }

  describe "#initialize_error_options" do
    subject { error_options }

    it "does not include filename when file is nil" do
      assert_nil subject[:filename]
    end

    describe "with an ActiveStorage::Attached object" do
      let(:file) { user.avatar.attach(file_1ko) and user.avatar }

      it "includes filename" do
        assert_equal subject[:filename], "file_1ko.png"
      end
    end

    describe "with an ActiveStorage::Attachment object" do
      let(:file) { user.avatar.attach(file_1ko) and user.avatar.attachment }

      it "includes filename" do
        assert_equal subject[:filename], "file_1ko.png"
      end
    end

    describe "with an ActiveStorage::Blob object" do
      let(:file) { user.avatar.attach(file_1ko) and user.avatar.blob }

      it "includes filename" do
        assert_equal subject[:filename], "file_1ko.png"
      end
    end

    describe "with a signed blob id String" do
      let(:file) { blob_file_1ko.signed_id }

      it "includes filename" do
        assert_equal subject[:filename], "file_1ko"
      end
    end

    describe "with a Hash object" do
      let(:file) { file_1ko }

      it "includes filename" do
        assert_equal subject[:filename], "file_1ko.png"
      end
    end
  end
end
