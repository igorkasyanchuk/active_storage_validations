# frozen_string_literal: true

# == Schema Information
#
# Table name: aspect_ratio_validator_check_validity_invalid_is_xy_arguments
#
#  id         :integer          not null, primary key
#  created_at :datetime         not null
#  updated_at :datetime         not null
#

class AspectRatio::Validator::CheckValidityInvalidIsXyArgument < ApplicationRecord
  has_one_attached :invalid
  validates :invalid, aspect_ratio: :is_0_1
end
