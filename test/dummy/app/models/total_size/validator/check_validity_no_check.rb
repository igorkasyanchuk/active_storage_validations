# frozen_string_literal: true

# == Schema Information
#
# Table name: total_size_validator_check_validity_no_checks
#
#  id         :integer          not null, primary key
#  created_at :datetime         not null
#  updated_at :datetime         not null
#

class TotalSize::Validator::CheckValidityNoCheck < ApplicationRecord
  has_many_attached :invalid
  validates :invalid, total_size: {}
end
