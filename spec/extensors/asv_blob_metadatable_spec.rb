# frozen_string_literal: true

require "rails_helper"

RSpec.describe ActiveStorageValidations::ASVBlobMetadatable do
  let(:blob) { ActiveStorage::Blob.new }

  describe "#active_storage_validations_metadata" do
    it "adds our gem's getter method to ActiveStorage::Blob custom metadata" do
      expect(blob).to respond_to(:active_storage_validations_metadata)
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

      expect(blob.active_storage_validations_metadata).to eq({ "duration" => 2.0, "audio" => false, "width" => 100 })

      if Rails.gem_version >= Gem::Version.new("7.0.0.rc1")
        expect(blob.custom_metadata).to eq({ "asv_duration" => "2.0", "asv_audio" => "false", "asv_width" => "100" })
      else
        expect(blob.metadata[:custom]).to eq({ "asv_duration" => "2.0", "asv_audio" => "false", "asv_width" => "100" })
      end
    end
  end

  describe "#remove_active_storage_validations_metadata!" do
    context "when the blob has our gem's metadata" do
      before do
        if Rails.gem_version >= Gem::Version.new("7.0.0.rc1")
          blob.custom_metadata = { "asv_duration" => "1.0", "asv_width" => "100" }
        else
          blob.metadata[:custom] = { "asv_duration" => "1.0", "asv_width" => "100" }
        end
      end

      it "removes our gem's metadata from ActiveStorage::Blob custom metadata" do
        blob.remove_active_storage_validations_metadata!
        expect(blob.active_storage_validations_metadata).to be_empty
      end
    end

    context "when the blob does not have our gem's metadata" do
      it "does not raise an error and works fine" do
        blob.remove_active_storage_validations_metadata!
        expect(blob.active_storage_validations_metadata).to be_empty
      end
    end
  end
end
