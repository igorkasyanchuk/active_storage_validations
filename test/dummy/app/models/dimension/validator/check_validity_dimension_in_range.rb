# frozen_string_literal: true

# == Schema Information
#
# Table name: dimension_validator_check_validity_dimension_in_ranges
#
#  id         :integer          not null, primary key
#  created_at :datetime         not null
#  updated_at :datetime         not null
#

class Dimension::Validator::CheckValidityDimensionInRange < ApplicationRecord
  has_one_attached :valid
  validates :valid, dimension: { width: { in: 100..200 } }
end

