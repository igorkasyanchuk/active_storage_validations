# frozen_string_literal: true

# == Schema Information
#
# Table name: duration_validator_is_performance_optimizeds
#
#  id         :integer          not null, primary key
#  created_at :datetime         not null
#  updated_at :datetime         not null
#

class Duration::Validator::IsPerformanceOptimized < ApplicationRecord
  has_one_attached :is_performance_optimized
  has_many_attached :is_performance_optimizeds
  validates :is_performance_optimized, duration: { less_than: 2.seconds }
  validates :is_performance_optimizeds, duration: { less_than: 2.seconds }
end
