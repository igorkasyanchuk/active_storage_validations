# frozen_string_literal: true

# == Schema Information
#
# Table name: limit_validator_with_ons
#
#  id         :integer          not null, primary key
#  created_at :datetime         not null
#  updated_at :datetime         not null
#

class Limit::Validator::WithOn < ApplicationRecord
  has_one_attached :with_on
  validates :with_on, limit: { min: 1 }, on: %i(create update destroy custom)
end
