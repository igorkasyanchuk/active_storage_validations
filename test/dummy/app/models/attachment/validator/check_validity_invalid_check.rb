# frozen_string_literal: true

# == Schema Information
#
# Table name: attachment_validator_check_validity_invalid_checks
#
#  id         :integer          not null, primary key
#  created_at :datetime         not null
#  updated_at :datetime         not null
#

class Attachment::Validator::CheckValidityInvalidCheck < ApplicationRecord
  has_one_attached :invalid
  validate_attached :invalid, invalid_check: true
end
