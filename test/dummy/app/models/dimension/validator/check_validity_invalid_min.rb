# frozen_string_literal: true

# == Schema Information
#
# Table name: dimension_validator_check_validity_invalid_min_ins
#
#  id         :integer          not null, primary key
#  created_at :datetime         not null
#  updated_at :datetime         not null
#

class Dimension::Validator::CheckValidityInvalidMin < ApplicationRecord
  has_one_attached :invalid
  validates :invalid, dimension: { min: 15 }
end
