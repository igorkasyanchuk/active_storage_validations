# frozen_string_literal: true

require "test_helper"

describe ActiveStorageValidations::ASVBlobMetadatable do
  let(:blob) { ActiveStorage::Blob.new }

  describe "#active_storage_validations_metadata" do
    it "adds our gem's getter method to ActiveStorage::Blob custom metadata" do
      assert blob.respond_to?(:active_storage_validations_metadata)
    end
  end

  describe "#merge_into_active_storage_validations_metadata" do
    before do
      if Rails.gem_version >= Gem::Version.new("7.0.0.rc1")
        blob.custom_metadata = { "asv_duration" => "1.0", "asv_width" => "100" }
      else
        blob.metadata[:custom] = { "asv_duration" => "1.0", "asv_width" => "100" }
      end
    end

    it "adds our gem's setter method to ActiveStorage::Blob custom metadata" do
      blob.merge_into_active_storage_validations_metadata({ "duration" => 2.0, "audio" => false })

      assert blob.active_storage_validations_metadata == { "duration" => 2.0, "audio" => false, "width" => 100 }

      if Rails.gem_version >= Gem::Version.new("7.0.0.rc1")
        assert blob.custom_metadata == { "asv_duration" => "2.0", "asv_audio" => "false", "asv_width" => "100" }
      else
        assert blob.metadata[:custom] == { "asv_duration" => "2.0", "asv_audio" => "false", "asv_width" => "100" }
      end
    end
  end

  describe "#remove_active_storage_validations_metadata!" do
    describe "when the blob has our gem's metadata" do
      before do
        if Rails.gem_version >= Gem::Version.new("7.0.0.rc1")
          blob.custom_metadata = { "asv_duration" => "1.0", "asv_width" => "100" }
        else
          blob.metadata[:custom] = { "asv_duration" => "1.0", "asv_width" => "100" }
        end
      end

      it "removes our gem's metadata from ActiveStorage::Blob custom metadata" do
        blob.remove_active_storage_validations_metadata!
        assert blob.active_storage_validations_metadata.empty?
      end
    end

    describe "when the blob does not have our gem's metadata" do
      it "does not raise an error and works fine" do
        blob.remove_active_storage_validations_metadata!
        assert blob.active_storage_validations_metadata.empty?
      end
    end
  end
end
