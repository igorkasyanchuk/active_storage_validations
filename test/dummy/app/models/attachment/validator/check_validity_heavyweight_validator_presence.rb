# frozen_string_literal: true

# == Schema Information
#
# Table name: attachment_validator_check_validity_h_validator_presences
#
#  id         :integer          not null, primary key
#  created_at :datetime         not null
#  updated_at :datetime         not null
#

class Attachment::Validator::CheckValidityHeavyweightValidatorPresence < ApplicationRecord
  self.table_name = "attachment_validator_check_validity_h_validator_presences"

  has_one_attached :invalid
  validate_attached :invalid, aspect_ratio: :square
end
