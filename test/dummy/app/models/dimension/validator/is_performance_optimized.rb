# frozen_string_literal: true

# == Schema Information
#
# Table name: dimension_validator_is_performance_optimizeds
#
#  id         :integer          not null, primary key
#  created_at :datetime         not null
#  updated_at :datetime         not null
#

class Dimension::Validator::IsPerformanceOptimized < ApplicationRecord
  has_one_attached :is_performance_optimized
  has_many_attached :is_performance_optimizeds
  validates :is_performance_optimized, dimension: { width: 150, height: 150 }
  validates :is_performance_optimizeds, dimension: { width: 150, height: 150 }
end
