# frozen_string_literal: true

require 'test_helper'

describe ActiveStorageValidations::ASVBlobMetadatable do
  let(:blob) { ActiveStorage::Blob.new }

  describe "#active_storage_validations_metadata" do
    it "adds our gem's getter method to ActiveStorage::Blob custom metadata" do
      assert blob.respond_to?(:active_storage_validations_metadata)
    end
  end

  describe "#active_storage_validations_metadata=" do
    it "adds our gem's setter method to ActiveStorage::Blob custom metadata" do
      blob.active_storage_validations_metadata = { 'duration' => '1.0' }
      assert blob.active_storage_validations_metadata == { 'duration' => '1.0' }
    end
  end

  describe "#merge_into_active_storage_validations_metadata" do
    it "adds our gem's setter method to ActiveStorage::Blob custom metadata" do
      blob.active_storage_validations_metadata = { 'duration' => '1.0' }
      blob.merge_into_active_storage_validations_metadata({ 'duration' => '2.0', 'audio' => false })
      assert blob.active_storage_validations_metadata == { 'duration' => '2.0', 'audio' => false }
    end
  end
end
