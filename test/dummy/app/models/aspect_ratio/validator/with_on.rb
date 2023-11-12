# frozen_string_literal: true

# == Schema Information
#
# Table name: aspect_ratio_validator_with_ons
#
#  id         :integer          not null, primary key
#  created_at :datetime         not null
#  updated_at :datetime         not null
#

class AspectRatio::Validator::WithOn < ApplicationRecord
  has_one_attached :with_on
  validates :with_on, aspect_ratio: :square, on: %i(create update destroy custom)
end
