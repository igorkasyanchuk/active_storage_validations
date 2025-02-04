# frozen_string_literal: true

# == Schema Information
#
# Table name: dimension_validator_check_validity_min_ranges
#
#  id         :integer          not null, primary key
#  created_at :datetime         not null
#  updated_at :datetime         not null
#

class Dimension::Validator::CheckValidityMinRange < ApplicationRecord
  has_one_attached :invalid
  validates :invalid, dimension: { min: 15..100 }
end
