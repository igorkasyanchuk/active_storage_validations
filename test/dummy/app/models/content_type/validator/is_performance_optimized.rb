# frozen_string_literal: true

# == Schema Information
#
# Table name: content_type_validator_is_performance_optimizeds
#
#  id         :integer          not null, primary key
#  created_at :datetime         not null
#  updated_at :datetime         not null
#

class ContentType::Validator::IsPerformanceOptimized < ApplicationRecord
  has_one_attached :is_performance_optimized
  has_many_attached :is_performance_optimizeds
  validates :is_performance_optimized, content_type: { with: :png, spoofing_protection: true }
  validates :is_performance_optimizeds, content_type: { with: :png, spoofing_protection: true }
end
