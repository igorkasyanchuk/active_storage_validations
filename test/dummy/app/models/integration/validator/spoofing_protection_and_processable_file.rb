# frozen_string_literal: true

# == Schema Information
#
# Table name: integration_validator_spoofing_protection_and_processable_files
#
#  id         :integer          not null, primary key
#  created_at :datetime         not null
#  updated_at :datetime         not null
#

class Integration::Validator::SpoofingProtectionAndProcessableFile < ApplicationRecord
  # Declared before the processable_file validator on purpose: content_type runs
  # first and caches asv_content_type on the blob.
  has_one_attached :spoofing_protection_first
  validates :spoofing_protection_first, content_type: { with: :png, spoofing_protection: true },
                                        processable_file: true

  has_one_attached :processable_file_first
  validates :processable_file_first, processable_file: true,
                                     content_type: { with: :png, spoofing_protection: true }
end
