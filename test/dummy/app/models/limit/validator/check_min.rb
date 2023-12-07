# frozen_string_literal: true

# == Schema Information
#
# Table name: limit_validator_check_mins
#
#  id         :integer          not null, primary key
#  created_at :datetime         not null
#  updated_at :datetime         not null
#

class Limit::Validator::CheckMin < ApplicationRecord
  has_many_attached :min
  validates :min, limit: { min: 2 }
end
