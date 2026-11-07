# frozen_string_literal: true

require "rails_helper"

# Proc options of the validators that analyze each file were evaluated again
# for every attached file: a Proc running a query made N+1 queries.
RSpec.describe "Proc options with several attached files" do
  subject(:record) do
    klass.new(title: "Title").tap do |model|
      model.images.attach([ image_150x150_file, image_150x150_file, image_150x150_file ])
      model.documents.attach([ pdf_5_pages_file, pdf_5_pages_file, pdf_5_pages_file ])
      model.videos.attach([ video_with_audio_file, video_with_audio_file, video_with_audio_file ])
    end
  end

  let(:klass) do
    Class.new(ApplicationRecord) do
      self.table_name = "projects"
      def self.name = "ProcOptionsCheck"

      def proc_calls = @proc_calls ||= Hash.new(0)

      has_many_attached :images
      has_many_attached :documents
      has_many_attached :videos
      validates :images, dimension: { width: ->(record) { record.proc_calls[:dimension] += 1 and { max: 1000 } } }
      validates :images, aspect_ratio: ->(record) { record.proc_calls[:aspect_ratio] += 1 and :square }
      validates :documents, pages: { less_than_or_equal_to: ->(record) { record.proc_calls[:pages] += 1 and 10 } }
      validates :videos, with_audio: { with: ->(record) { record.proc_calls[:with_audio] += 1 and true } }
    end
  end

  before { record.valid? }

  it { expect(record.errors).to be_empty }
  it { expect(record.proc_calls).to eq({ dimension: 1, aspect_ratio: 1, pages: 1, with_audio: 1 }) }
end
