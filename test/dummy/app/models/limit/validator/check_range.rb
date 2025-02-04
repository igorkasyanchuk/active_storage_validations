# frozen_string_literal: true

# == Schema Information
#
# Table name: limit_validator_check_ranges
#
#  id         :integer          not null, primary key
#  created_at :datetime         not null
#  updated_at :datetime         not null
#

class Limit::Validator::CheckRange < ApplicationRecord
  has_many_attached :range
  validates :range, limit: { min: 1, max: 3 }
end
