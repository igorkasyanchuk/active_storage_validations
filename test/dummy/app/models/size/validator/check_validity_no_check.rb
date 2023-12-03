# frozen_string_literal: true

# == Schema Information
#
# Table name: size_validator_check_validity_no_checks
#
#  id         :integer          not null, primary key
#  created_at :datetime         not null
#  updated_at :datetime         not null
#

class Size::Validator::CheckValidityNoCheck < ApplicationRecord
  has_one_attached :invalid
  validates :invalid, size: {}
end
