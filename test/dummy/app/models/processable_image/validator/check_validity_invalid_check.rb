# frozen_string_literal: true

# == Schema Information
#
# Table name: processable_image_validator_check_validity_invalid_checks
#
#  id         :integer          not null, primary key
#  created_at :datetime         not null
#  updated_at :datetime         not null
#

class ProcessableImage::Validator::CheckValidityInvalidCheck < ApplicationRecord
  has_one_attached :invalid
  validates :invalid, processable_image: { invalid_check: true }
end
