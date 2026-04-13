# frozen_string_literal: true

# == Schema Information
#
# Table name: attachment_validator_check_validity_no_checks
#
#  id         :integer          not null, primary key
#  created_at :datetime         not null
#  updated_at :datetime         not null
#

class Attachment::Validator::CheckValidityNoCheck < ApplicationRecord
  has_one_attached :invalid
  validate_attached :invalid
end
