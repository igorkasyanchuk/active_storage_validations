# frozen_string_literal: true

# == Schema Information
#
# Table name: integration_validator_without_new_files
#
#  id         :integer          not null, primary key
#  created_at :datetime         not null
#  updated_at :datetime         not null
#

# Every metadata validator, on has_many_attached relations: validating a saved
# record without new files must not query their attachments.
class Integration::Validator::WithoutNewFile < ApplicationRecord
  has_many_attached :images
  validates :images,
            dimension: { width: { max: 1000 } },
            aspect_ratio: :square,
            content_type: :png,
            processable_file: true

  has_many_attached :documents
  validates :documents, pages: { less_than_or_equal_to: 10 }

  has_many_attached :videos
  validates :videos, with_audio: true

  has_many_attached :audios
  validates :audios, duration: { less_than: 10.minutes }
end
