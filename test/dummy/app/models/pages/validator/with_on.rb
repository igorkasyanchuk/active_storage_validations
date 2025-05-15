# frozen_string_literal: true

# == Schema Information
#
# Table name: pages_validator_with_ons
#
#  id         :integer          not null, primary key
#  created_at :datetime         not null
#  updated_at :datetime         not null
#

class Pages::Validator::WithOn < ApplicationRecord
  has_one_attached :with_on
  validates :with_on, pages: { equal_to: 5 }, on: %i[create update destroy custom]
end
