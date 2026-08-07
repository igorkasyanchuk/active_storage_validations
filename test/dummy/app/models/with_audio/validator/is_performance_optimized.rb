# frozen_string_literal: true

class WithAudio::Validator::IsPerformanceOptimized < ApplicationRecord
  has_one_attached :is_performance_optimized
  has_many_attached :is_performance_optimizeds
  validates :is_performance_optimized, with_audio: true
  validates :is_performance_optimizeds, with_audio: true
end
