# frozen_string_literal: true

require "rails_helper"

# Validating a saved record whose files did not change ran an EXISTS query on
# active_storage_attachments for every validator of every has_many_attached:
# twice per metadata validator (ActiveModel's `value.blank?`, then the
# validator's own `attached?`), although those validators only check new files.
RSpec.describe "Validating a saved record without new files" do
  subject(:record) { klass.find(saved_record.id) }

  let(:klass) { Integration::Validator::WithoutNewFile }
  let(:saved_record) do
    klass.create!(
      images: [ image_150x150_file ],
      documents: [ pdf_5_pages_file ],
      videos: [ video_with_audio_file ],
      audios: [ audio_file ]
    )
  end

  before { record }

  def queries_during
    queries = []
    subscriber = ActiveSupport::Notifications.subscribe("sql.active_record") do |*, payload|
      queries << payload[:sql] unless payload[:name] == "SCHEMA"
    end
    yield
    queries
  ensure
    ActiveSupport::Notifications.unsubscribe(subscriber)
  end

  it { is_expected_to_be_valid }

  it "does not query the attachments of the metadata validators" do
    expect(queries_during { record.valid? }).to be_empty
  end

  context "with :allow_blank" do
    let(:klass) { Integration::Validator::WithoutNewFileAllowBlank }
    let(:saved_record) { klass.create!(images: [ image_150x150_file ]) }

    it "keeps Active Model's blank check" do
      expect(queries_during { record.valid? }.size).to eq(1)
    end
  end
end
