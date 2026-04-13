# frozen_string_literal: true

# == Schema Information
#
# Table name: aspect_ratio_validator_optimized_with_blob_metadatas
#
#  id         :integer          not null, primary key
#  created_at :datetime         not null
#  updated_at :datetime         not null
#

class AspectRatio::Validator::OptimizedWithBlobMetadata < ApplicationRecord
  has_one_attached :optimized_with_blob_metadata
  has_many_attached :optimized_with_blob_metadatas
  validates :optimized_with_blob_metadata, aspect_ratio: :square
  validates :optimized_with_blob_metadatas, aspect_ratio: :square
end
