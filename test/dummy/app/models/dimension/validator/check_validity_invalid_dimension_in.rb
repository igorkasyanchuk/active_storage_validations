# frozen_string_literal: true

# == Schema Information
#
# Table name: dimension_validator_check_validity_invalid_dimension_ins
#
#  id         :integer          not null, primary key
#  created_at :datetime         not null
#  updated_at :datetime         not null
#

class Dimension::Validator::CheckValidityInvalidDimensionIn < ApplicationRecord
  has_one_attached :invalid
  validates :invalid, dimension: { width: { in: 15 } }
end

