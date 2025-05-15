# frozen_string_literal: true

# == Schema Information
#
# Table name: pages_validator_is_performance_optimizeds
#
#  id         :integer          not null, primary key
#  created_at :datetime         not null
#  updated_at :datetime         not null
#

class Pages::Validator::IsPerformanceOptimized < ApplicationRecord
  has_one_attached :is_performance_optimized
  has_many_attached :is_performance_optimizeds
  validates :is_performance_optimized, pages: { less_than_or_equal_to: 5 }
  validates :is_performance_optimizeds, pages: { less_than_or_equal_to: 5 }
end
