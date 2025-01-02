# frozen_string_literal: true

# == Schema Information
#
# Table name: processable_file_validator_is_performance_optimizeds
#
#  id         :integer          not null, primary key
#  created_at :datetime         not null
#  updated_at :datetime         not null
#

class ProcessableFile::Validator::IsPerformanceOptimized < ApplicationRecord
  has_one_attached :is_performance_optimized
  has_many_attached :is_performance_optimizeds
  validates :is_performance_optimized, processable_file: true
  validates :is_performance_optimizeds, processable_file: true
end
