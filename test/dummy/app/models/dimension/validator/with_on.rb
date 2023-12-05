# frozen_string_literal: true

# == Schema Information
#
# Table name: dimension_validator_with_ons
#
#  id         :integer          not null, primary key
#  created_at :datetime         not null
#  updated_at :datetime         not null
#

class Dimension::Validator::WithOn < ApplicationRecord
  has_one_attached :with_on
  validates :with_on, dimension: { width: 150, height: 150 }, on: %i(create update destroy custom)
end
