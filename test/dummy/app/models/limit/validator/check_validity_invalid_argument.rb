# frozen_string_literal: true

# == Schema Information
#
# Table name: limit_validator_check_validity_invalid_arguments
#
#  id         :integer          not null, primary key
#  created_at :datetime         not null
#  updated_at :datetime         not null
#

class Limit::Validator::CheckValidityInvalidArgument < ApplicationRecord
  has_one_attached :invalid
  validates :invalid, limit: { min: '1' }
end
