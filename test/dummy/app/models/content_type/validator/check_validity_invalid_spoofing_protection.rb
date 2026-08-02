# frozen_string_literal: true

# == Schema Information
#
# Table name: content_type_validator_check_validity_invalid_spoof_protections
#
#  id         :integer          not null, primary key
#  created_at :datetime         not null
#  updated_at :datetime         not null
#

class ContentType::Validator::CheckValidityInvalidSpoofingProtection < ApplicationRecord
  self.table_name = "content_type_validator_check_validity_invalid_spoof_protections"

  has_one_attached :invalid
  validates :invalid, content_type: { with: :png, spoofing_protection: :unknown }
end
