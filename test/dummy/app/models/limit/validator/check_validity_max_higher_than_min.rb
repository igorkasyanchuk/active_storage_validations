# frozen_string_literal: true

# == Schema Information
#
# Table name: limit_validator_check_validity_max_higher_than_mins
#
#  id         :integer          not null, primary key
#  created_at :datetime         not null
#  updated_at :datetime         not null
#

class Limit::Validator::CheckValidityMaxHigherThanMin < ApplicationRecord
  has_one_attached :invalid
  validates :invalid, limit: { min: 5, max: 3 }
end
