# frozen_string_literal: true

# == Schema Information
#
# Table name: size_validator_with_ons
#
#  id         :integer          not null, primary key
#  created_at :datetime         not null
#  updated_at :datetime         not null
#

class Size::Validator::WithOn < ApplicationRecord
  has_one_attached :with_on
  validates :with_on, size: { less_than: 2.kilobytes }, on: %i(create update destroy custom)
end
