# frozen_string_literal: true

# == Schema Information
#
# Table name: limit_validator_check_maxs
#
#  id         :integer          not null, primary key
#  created_at :datetime         not null
#  updated_at :datetime         not null
#

class Limit::Validator::CheckMax < ApplicationRecord
  has_many_attached :max
  validates :max, limit: { max: 1 }
end
