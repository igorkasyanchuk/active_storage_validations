# frozen_string_literal: true

# == Schema Information
#
# Table name: total_size_validator_check_validity_invalid_checks
#
#  id         :integer          not null, primary key
#  created_at :datetime         not null
#  updated_at :datetime         not null
#

class TotalSize::Validator::CheckValidityInvalidCheck < ApplicationRecord
  has_many_attached :invalid
  validates :invalid, total_size: { invalid_check: true }
end
