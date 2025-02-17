# frozen_string_literal: true

# == Schema Information
#
# Table name: content_type_validator_check_validity_valid_ct_ole_storages
#
#  id         :integer          not null, primary key
#  created_at :datetime         not null
#  updated_at :datetime         not null
#

class ContentType::Validator::CheckValidityValidContentTypeOleStorage < ApplicationRecord
  self.table_name = "content_type_validator_check_validity_valid_ct_ole_storages"

  has_one_attached :valid
  validates :valid, content_type: "application/x-ole-storage"
end
