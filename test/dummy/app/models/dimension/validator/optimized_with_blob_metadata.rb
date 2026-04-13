# frozen_string_literal: true

# == Schema Information
#
# Table name: dimension_validator_optimized_with_blob_metadatas
#
#  id         :integer          not null, primary key
#  created_at :datetime         not null
#  updated_at :datetime         not null
#

class Dimension::Validator::OptimizedWithBlobMetadata < ApplicationRecord
  has_one_attached :optimized_with_blob_metadata
  has_many_attached :optimized_with_blob_metadatas
  validates :optimized_with_blob_metadata, dimension: { width: 150, height: 150 }
  validates :optimized_with_blob_metadatas, dimension: { width: 150, height: 150 }
end
