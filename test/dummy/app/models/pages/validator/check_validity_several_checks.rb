# frozen_string_literal: true

# == Schema Information
#
# Table name: pages_validator_check_validity_several_checks
#
#  id         :integer          not null, primary key
#  created_at :datetime         not null
#  updated_at :datetime         not null
#

class Pages::Validator::CheckValiditySeveralChecks < ApplicationRecord
  has_one_attached :invalid
  validates :invalid, pages: { less_than: 2, greater_than_or_equal_to: 7 }
end
