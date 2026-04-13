# frozen_string_literal: true

# == Schema Information
#
# Table name: pages_validator_optimized_with_blob_metadatas
#
#  id         :integer          not null, primary key
#  created_at :datetime         not null
#  updated_at :datetime         not null
#

class Pages::Validator::OptimizedWithBlobMetadata < ApplicationRecord
  has_one_attached :optimized_with_blob_metadata
  has_many_attached :optimized_with_blob_metadatas
  validates :optimized_with_blob_metadata, pages: { less_than_or_equal_to: 5 }
  validates :optimized_with_blob_metadatas, pages: { less_than_or_equal_to: 5 }
end
