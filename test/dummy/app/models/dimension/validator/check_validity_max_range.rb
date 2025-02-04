# frozen_string_literal: true

# == Schema Information
#
# Table name: dimension_validator_check_validity_max_ranges
#
#  id         :integer          not null, primary key
#  created_at :datetime         not null
#  updated_at :datetime         not null
#

class Dimension::Validator::CheckValidityMaxRange < ApplicationRecord
  has_one_attached :invalid
  validates :invalid, dimension: { max: 15..100 }
end
