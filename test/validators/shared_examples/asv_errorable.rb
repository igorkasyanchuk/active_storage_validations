module ASVErrorable
  extend ActiveSupport::Concern

  included do
    let(:validator_klass) { "ActiveStorageValidations::#{validator_test_class.name.sub(/::/, '')}".constantize }
    let(:validator) { validator_klass.allocate }
    let(:user) { User.new(name: "ASV Errorable") }
    let(:file) { nil }
    let(:error_options) { validator.send(:initialize_error_options, {}, file) }

    describe "when file is nil" do
      it "does not include filename" do
        assert_nil error_options[:filename]
      end
    end

    describe "when file is an ActiveStorage::Attached object" do
      let(:file) { user.avatar.attach(file_1ko) and user.avatar }

      it "includes filename" do
        assert_equal "file_1ko.png", error_options[:filename]
      end
    end

    describe "when file is an ActiveStorage::Attachment object" do
      let(:file) { user.avatar.attach(file_1ko) and user.avatar.attachment }

      it "includes filename" do
        assert_equal "file_1ko.png", error_options[:filename]
      end
    end

    describe "when file is an ActiveStorage::Blob object" do
      let(:file) { user.avatar.attach(file_1ko) and user.avatar.blob }

      it "includes filename" do
        assert_equal "file_1ko.png", error_options[:filename]
      end
    end

    describe "when file is a signed blob id String" do
      let(:file) { blob_file_1ko.signed_id }

      it "includes filename" do
        assert_equal "file_1ko", error_options[:filename]
      end
    end

    describe "when file is a Hash object" do
      let(:file) { file_1ko }

      it "includes filename" do
        assert_equal "file_1ko.png", error_options[:filename]
      end
    end
  end
end
