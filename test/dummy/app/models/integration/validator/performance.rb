# frozen_string_literal: true

# == Schema Information
#
# Table name: integration_validator_performances
#
#  id         :integer          not null, primary key
#  created_at :datetime         not null
#  updated_at :datetime         not null
#

class Integration::Validator::Performance < ApplicationRecord
  has_many_attached :pictures
  validates :pictures,
            aspect_ratio: :square,
            dimension: { min: 80..80, max: 600..600 }

  has_many_attached :videos
  validates :videos,
            dimension: { min: 80..80, max: 600..600 },
            content_type: { with: :mp4, spoofing_protection: true }
end
