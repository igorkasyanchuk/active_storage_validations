# frozen_string_literal: true

# == Schema Information
#
# Table name: attached_validator_check_validity_no_checks
#
#  id         :integer          not null, primary key
#  created_at :datetime         not null
#  updated_at :datetime         not null
#

class Attached::Validator::CheckValidityNoCheck < ApplicationRecord
  has_one_attached :invalid
  validates :invalid, attached: {}
end
