# frozen_string_literal: true

require "rails_helper"
require "active_storage_validations/matchers"

# Rails 8.2 analyzes attachments on attach by default (config.active_storage
# .analyze = :immediately), so validating a probe ran Active Storage's own
# analyzers (ImageMagick / libvips, ffprobe) on every probe file, about 2000
# times over the matcher suite. Validators only read the gem's asv_* metadata.
RSpec.describe ActiveStorageValidations::Matchers::ASVAttachable do
  include ActiveStorageValidations::Matchers

  let(:klass) do
    Class.new(ApplicationRecord) do
      self.table_name = "size_matchers"
      def self.name = "ProbeAnalysisMatcherProbe"

      has_one_attached :avatar
      has_one_attached :video
      has_many_attached :photos
      validates :avatar, content_type: :png, dimension: { width: { max: 800 } }, processable_file: true
      validates :video, with_audio: true
      validates :photos, limit: { max: 2 }, total_size: { less_than: 2.kilobytes }
    end
  end

  let(:matchers) do
    [
      validate_content_type_of(:avatar).allowing(:png).rejecting(:gif),
      validate_dimensions_of(:avatar).width_max(800),
      validate_processable_file_of(:avatar),
      validate_with_audio_of(:video),
      validate_limits_of(:photos).max(2),
      validate_total_size_of(:photos).less_than(2.kilobytes)
    ]
  end

  let(:probe_blobs) { [] }
  let(:rails_analyzed_blobs) { [] }

  around do |example|
    if ActiveStorage.respond_to?(:analyze=)
      analyze = ActiveStorage.analyze
      ActiveStorage.analyze = :immediately
      example.run
    else
      example.run
    end
  ensure
    ActiveStorage.analyze = analyze if analyze
  end

  before do
    allow(ActiveStorage::Blob).to receive(:build_after_unfurling).and_wrap_original do |original, **kwargs|
      original.call(**kwargs).tap do |blob|
        probe_blobs << blob
        # Attach-time analysis (Rails 8.2+) goes through this method.
        next unless blob.respond_to?(:analyze_without_saving)

        allow(blob).to receive(:analyze_without_saving).and_wrap_original do |analyze, *args|
          rails_analyzed_blobs << blob
          analyze.call(*args)
        end
      end
    end
  end

  describe "probe attachments" do
    it "match" do
      expect(matchers.map { |matcher| matcher.matches?(klass) }).to all(be(true))
    end

    it "are marked analyzed" do
      matchers.each { |matcher| matcher.matches?(klass) }

      expect(probe_blobs).to be_present.and all(be_analyzed)
    end

    it "are not analyzed by Active Storage" do
      matchers.each { |matcher| matcher.matches?(klass) }

      expect(rails_analyzed_blobs).to be_empty
    end
  end
end
