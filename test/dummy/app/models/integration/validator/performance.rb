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
  has_one_attached :picture
  validates :picture,
            aspect_ratio: :square,
            dimension: { min: 80..600, max: 80..600 }

  has_one_attached :video
  validates :video,
            dimension: { min: 80..600, max: 80..600 },
            duration: { less_than: 10.seconds }
end
