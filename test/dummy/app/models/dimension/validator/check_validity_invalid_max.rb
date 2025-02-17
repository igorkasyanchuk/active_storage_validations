# frozen_string_literal: true

# == Schema Information
#
# Table name: dimension_validator_check_validity_invalid_max_ins
#
#  id         :integer          not null, primary key
#  created_at :datetime         not null
#  updated_at :datetime         not null
#

class Dimension::Validator::CheckValidityInvalidMax < ApplicationRecord
  has_one_attached :invalid
  validates :invalid, dimension: { max: 15 }
end
