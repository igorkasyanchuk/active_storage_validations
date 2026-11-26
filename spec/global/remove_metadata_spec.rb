# frozen_string_literal: true

require "rails_helper"
require "rake"

# A cached value is trusted as is, including a value an analyzer could not
# extract: an upgrade that improves an analyzer needs a way to clear the cache
# of the blobs already saved.
RSpec.describe ActiveStorageValidations do
  def create_blob(fixture, content_type, custom_metadata)
    ActiveStorage::Blob.create_and_upload!(
      io: open_fixture(Rails.root.join("public", fixture)),
      filename: fixture,
      content_type: content_type,
      identify: false
    ).tap { |blob| blob.update!(custom_metadata: custom_metadata) }
  end

  let!(:png_blob) { create_blob("image_150x150.png", "image/png", { "asv_width" => "150", "other" => "keep" }) }
  let!(:webm_blob) { create_blob("audio_4s_no_duration.webm", "video/webm", { "asv_duration" => "" }) }
  let!(:untouched_blob) { create_blob("image_150x150.png", "image/png", { "other" => "keep" }) }

  describe ".remove_metadata!" do
    it "clears the asv_* keys of every blob and keeps other custom metadata" do
      described_class.remove_metadata!

      expect(png_blob.reload.custom_metadata).to eq({ "other" => "keep" })
      expect(webm_blob.reload.custom_metadata).to eq({})
      expect(untouched_blob.reload.custom_metadata).to eq({ "other" => "keep" })
    end

    it "returns the number of blobs updated" do
      expect(described_class.remove_metadata!).to eq(2)
    end

    it "only clears the blobs of a given relation" do
      described_class.remove_metadata!(ActiveStorage::Blob.where(content_type: "video/webm"))

      expect(png_blob.reload.active_storage_validations_metadata).to eq({ "width" => 150 })
      expect(webm_blob.reload.active_storage_validations_metadata).to be_empty
    end

    it "does not touch the attached records" do
      project = Project.new(title: "Title").tap { |record| record.save!(validate: false) }
      ActiveStorage::Attachment.create!(name: "documents", record: project, blob: png_blob)
      project.update_column(:updated_at, 1.day.ago)

      expect { described_class.remove_metadata! }.not_to(change { project.reload.updated_at })
    end
  end

  describe "rake active_storage_validations:remove_metadata" do
    subject(:run_task) { rake_application["active_storage_validations:remove_metadata"].invoke }

    let(:rake_application) do
      Rake::Application.new.tap do |application|
        Rake.application = application
        Rails.application.load_tasks
      end
    end

    around do |example|
      original_application = Rake.application
      original_content_type = ENV.fetch("CONTENT_TYPE", nil)
      example.run
    ensure
      ENV["CONTENT_TYPE"] = original_content_type
      Rake.application = original_application
    end

    it "clears the cache of every blob" do
      expect { run_task }.to output("Cleared the active_storage_validations metadata of 2 blob(s).\n").to_stdout
      expect(png_blob.reload.active_storage_validations_metadata).to be_empty
    end

    it "only clears the blobs of the CONTENT_TYPE list" do
      ENV["CONTENT_TYPE"] = "video/webm, audio/ogg"

      expect { run_task }.to output(/of 1 blob/).to_stdout
      expect(png_blob.reload.active_storage_validations_metadata).to eq({ "width" => 150 })
    end
  end
end
