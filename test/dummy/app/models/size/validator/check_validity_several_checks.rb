# frozen_string_literal: true

# == Schema Information
#
# Table name: size_validator_check_validity_several_checks
#
#  id         :integer          not null, primary key
#  created_at :datetime         not null
#  updated_at :datetime         not null
#

class Size::Validator::CheckValiditySeveralChecks < ApplicationRecord
  has_one_attached :invalid
  validates :invalid, size: { less_than: 2.kilobytes, greater_than_or_equal_to: 7.kilobytes }
end
