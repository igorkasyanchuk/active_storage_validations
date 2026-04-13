# frozen_string_literal: true

# == Schema Information
#
# Table name: processable_file_validator_optimized_with_blob_metadatas
#
#  id         :integer          not null, primary key
#  created_at :datetime         not null
#  updated_at :datetime         not null
#

class ProcessableFile::Validator::OptimizedWithBlobMetadata < ApplicationRecord
  has_one_attached :optimized_with_blob_metadata
  has_many_attached :optimized_with_blob_metadatas
  validates :optimized_with_blob_metadata, processable_file: true
  validates :optimized_with_blob_metadatas, processable_file: true
end
