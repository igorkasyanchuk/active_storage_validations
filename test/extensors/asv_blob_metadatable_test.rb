# frozen_string_literal: true

require 'test_helper'

describe ActiveStorageValidations::ASVBlobMetadatable do
  let(:blob) { ActiveStorage::Blob.new }

  it "adds our gem's getter method to ActiveStorage::Blob custom metadata" do
    assert blob.respond_to?(:active_storage_validations_metadata)
  end

  it "adds our gem's setter method to ActiveStorage::Blob custom metadata" do
    blob.active_storage_validations_metadata = { 'duration' => '1.0' }
    assert blob.active_storage_validations_metadata == { 'duration' => '1.0' }
  end
end
