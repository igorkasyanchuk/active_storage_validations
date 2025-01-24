# frozen_string_literal: true

# == Schema Information
#
# Table name: aspect_ratio_validator_is_performance_optimizeds
#
#  id         :integer          not null, primary key
#  created_at :datetime         not null
#  updated_at :datetime         not null
#

class AspectRatio::Validator::IsPerformanceOptimized < ApplicationRecord
  has_one_attached :is_performance_optimized
  has_many_attached :is_performance_optimizeds
  validates :is_performance_optimized, aspect_ratio: :square
  validates :is_performance_optimizeds, aspect_ratio: :square
end
