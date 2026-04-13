# frozen_string_literal: true

# == Schema Information
#
# Table name: content_type_validator_optimized_with_blob_metadatas
#
#  id         :integer          not null, primary key
#  created_at :datetime         not null
#  updated_at :datetime         not null
#

class ContentType::Validator::OptimizedWithBlobMetadata < ApplicationRecord
  has_one_attached :optimized_with_blob_metadata
  has_many_attached :optimized_with_blob_metadatas
  validates :optimized_with_blob_metadata, content_type: { with: :png, spoofing_protection: true }
  validates :optimized_with_blob_metadatas, content_type: { with: :png, spoofing_protection: true }
end
