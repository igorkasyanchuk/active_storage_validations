# frozen_string_literal: true

require "rails_helper"

# Rails' direct upload endpoint permits `metadata: {}` from the client and only
# strips analyzed / identified / composed, and the signed id it returns can be
# attached to any attachment param. A forged asv_* cache must not skip the
# gem's analysis: new blobs drop asv_* keys when they are initialized.
RSpec.describe "forged asv_* metadata" do
  def direct_upload(path, filename:, content_type:, custom_metadata:)
    data = File.binread(path)
    blob = ActiveStorage::Blob.create_before_direct_upload!(
      filename: filename,
      byte_size: data.bytesize,
      checksum: OpenSSL::Digest::MD5.base64digest(data),
      content_type: content_type,
      metadata: { custom: custom_metadata }
    )
    blob.service.upload(blob.key, StringIO.new(data), checksum: blob.checksum)
    blob
  end

  context "with forged dimensions" do
    # validates :width_max, dimension: { width: { max: 500 } }
    subject(:model) { Dimension::Validator::Check.new }

    let(:blob) do
      direct_upload(
        Rails.root.join("public", "image_700x500.png"),
        filename: "image_700x500.png",
        content_type: "image/png",
        custom_metadata: { asv_width: "100", asv_height: "100" }
      )
    end

    before { model.width_max.attach(blob.signed_id) }

    it "analyzes the file and rejects it" do
      expect(model).not_to be_valid
      expect(model.errors.details[:width_max]).to include(a_hash_including(error: :dimension_width_not_less_than_or_equal_to, validator_type: :dimension))
    end
  end

  context "with a forged analysis of an unprocessable file" do
    # validates :has_to_be_processable, processable_file: true
    subject(:model) { ProcessableFile::Validator::Check.new }

    # A PNG cut short after its header: identified as a PNG, but no image
    # processor can decode it.
    let(:blob) do
      direct_upload(
        Rails.root.join("public", "image_150x150_truncated.png"),
        filename: "image_150x150_truncated.png",
        content_type: "image/png",
        custom_metadata: { asv_width: "150", asv_height: "150" }
      )
    end

    before { model.has_to_be_processable.attach(blob.signed_id) }

    it "analyzes the file and rejects it" do
      expect(model).not_to be_valid
      expect(model.errors.details[:has_to_be_processable]).to include(a_hash_including(error: :file_not_processable))
    end
  end

  context "with a forged cache in an attach(io:, metadata:) hash" do
    # validates :width_max, dimension: { width: { max: 500 } }
    subject(:model) { Dimension::Validator::Check.new }

    before do
      model.width_max.attach(
        image_700x500_file.merge(metadata: { custom: { asv_width: "100", asv_height: "100", other: "keep" } })
      )
    end

    it "analyzes the file and rejects it" do
      expect(model).not_to be_valid
      expect(model.errors.details[:width_max]).to include(a_hash_including(error: :dimension_width_not_less_than_or_equal_to))
    end

    it "keeps the other custom metadata" do
      expect(model.width_max.blob.custom_metadata).to eq({ "other" => "keep" })
    end
  end

  # Caches written by the gem, 4.x included, live on persisted blobs.
  context "with a cache already stored on a persisted blob" do
    # validates :width_max, dimension: { width: { max: 500 } }
    subject(:model) { Dimension::Validator::Check.new }

    let(:blob) do
      ActiveStorage::Blob.create_and_upload!(
        io: open_fixture(Rails.root.join("public", "image_700x500.png")),
        filename: "image_700x500.png",
        content_type: "image/png"
      ).tap do |persisted_blob|
        persisted_blob.custom_metadata = { "asv_width" => "100", "asv_height" => "100" }
        persisted_blob.save!
      end
    end

    before { model.width_max.attach(blob.signed_id) }

    it "trusts it and does not analyze the file again" do
      # rubocop:disable RSpec/AnyInstance -- analyzer created internally by the validator
      expect_any_instance_of(ActiveStorageValidations::Analyzer).not_to receive(:metadata)
      # rubocop:enable RSpec/AnyInstance
      expect(model).to be_valid
    end
  end
end
