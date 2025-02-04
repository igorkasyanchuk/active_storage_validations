# frozen_string_literal: true

# == Schema Information
#
# Table name: duration_validator_with_ons
#
#  id         :integer          not null, primary key
#  created_at :datetime         not null
#  updated_at :datetime         not null
#

class Duration::Validator::WithOn < ApplicationRecord
  has_one_attached :with_on
  validates :with_on, duration: { less_than: 2.seconds }, on: %i[create update destroy custom]
end
