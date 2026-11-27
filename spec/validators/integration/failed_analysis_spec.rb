# frozen_string_literal: true

require "rails_helper"

# An analysis that produces nothing is not cached on the blob, so every
# metadata validator of the attribute ran it again in the same validation
# (and ffprobe twice each time): four validators on a file that hangs ffprobe
# held the request for eight timeouts.
RSpec.describe "Validating a file that cannot be analyzed" do
  subject(:record) { klass.new(title: "Title").tap { |model| model.video.attach(unanalyzable_video) } }

  let(:unanalyzable_video) { fixture_file("video_file_0ko.mp4", filename: "video_file_0ko.mp4", content_type: "video/mp4") }
  let(:klass) do
    Class.new(ApplicationRecord) do
      self.table_name = "projects"
      def self.name = "FailedAnalysisCheck"

      has_one_attached :video
      validates :video,
                dimension: { width: { min: 100 } },
                duration: { less_than: 10.minutes },
                with_audio: true,
                processable_file: true
    end
  end

  def analyses_during
    analyses = 0
    subscriber = ActiveSupport::Notifications.subscribe("analyze.active_storage_validations") { analyses += 1 }
    yield
    analyses
  ensure
    ActiveSupport::Notifications.unsubscribe(subscriber)
  end

  def error_types(model)
    model.errors.map { |error| [ error.options[:validator_type], error.type ] }
  end

  it "analyzes the file once for all its validators" do
    expect(analyses_during { record.valid? }).to eq(1)
  end

  it "reports the error of every validator" do
    record.valid?

    expect(error_types(record)).to eq(
      [
        [ :dimension, :media_metadata_missing ],
        [ :duration, :media_metadata_missing ],
        [ :with_audio, :audio_missing ],
        [ :processable_file, :file_not_processable ]
      ]
    )
  end

  it "does not cache the failed analysis on the blob" do
    record.valid?

    expect(record.video.blob.active_storage_validations_metadata).to be_empty
  end

  context "when the record is validated again" do
    before { record.valid? }

    it "analyzes the file again" do
      expect(analyses_during { record.valid? }).to eq(1)
    end
  end

  context "when a later validation can analyze the file" do
    before do
      record.valid?
      # rubocop:disable RSpec/AnyInstance -- analyzer created internally by the validator
      allow_any_instance_of(ActiveStorageValidations::Analyzer::VideoAnalyzer).to receive(:metadata)
        .and_return({ width: 150, height: 150, duration: 1.0, audio: true, video: true })
      # rubocop:enable RSpec/AnyInstance
    end

    it { is_expected.to be_valid }
  end

  context "when the validators do not share the same timeout" do
    let(:klass) do
      Class.new(ApplicationRecord) do
        self.table_name = "projects"
        def self.name = "FailedAnalysisTimeoutCheck"

        has_one_attached :video
        validates :video,
                  dimension: { width: { min: 100 } },
                  duration: { less_than: 10.minutes, timeout: 30.seconds },
                  processable_file: true
      end
    end

    it "analyzes the file once per timeout" do
      expect(analyses_during { record.valid? }).to eq(2)
    end
  end

  context "with several files" do
    subject(:record) do
      klass.new(title: "Title").tap { |model| model.videos.attach([ unanalyzable_video, video_with_audio_file, other_unanalyzable_video ]) }
    end

    let(:other_unanalyzable_video) { fixture_file("video_file_0ko.mp4", filename: "other.mp4", content_type: "video/mp4") }
    let(:klass) do
      Class.new(ApplicationRecord) do
        self.table_name = "projects"
        def self.name = "FailedAnalysisManyCheck"

        has_many_attached :videos
        validates :videos, dimension: { width: { min: 100 } }, duration: { less_than: 10.minutes }, processable_file: true
      end
    end

    it "analyzes each file once" do
      expect(analyses_during { record.valid? }).to eq(3)
    end

    it "reports the errors of the unanalyzable files only" do
      record.valid?

      expect(record.errors.map { |error| error.options[:filename] }.tally).to eq(
        { "video_file_0ko.mp4" => 3, "other.mp4" => 3 }
      )
    end
  end

  context "when the file is missing from storage" do
    subject(:record) { klass.new(title: "Title").tap { |model| model.video.attach(blob.signed_id) } }

    let(:blob) { create_blob_from_file(video_with_audio_file) }

    before { blob.service.delete(blob.key) }

    it "reports attachment_missing for every validator" do
      record.valid?

      expect(record.errors.map(&:type)).to eq(%i[attachment_missing attachment_missing attachment_missing attachment_missing])
    end
  end
end
