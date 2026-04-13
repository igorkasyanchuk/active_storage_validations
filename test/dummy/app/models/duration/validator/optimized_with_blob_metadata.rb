# frozen_string_literal: true

# == Schema Information
#
# Table name: duration_validator_optimized_with_blob_metadatas
#
#  id         :integer          not null, primary key
#  created_at :datetime         not null
#  updated_at :datetime         not null
#

class Duration::Validator::OptimizedWithBlobMetadata < ApplicationRecord
  has_one_attached :optimized_with_blob_metadata
  has_many_attached :optimized_with_blob_metadatas
  validates :optimized_with_blob_metadata, duration: { less_than: 2.seconds }
  validates :optimized_with_blob_metadatas, duration: { less_than: 2.seconds }
end
