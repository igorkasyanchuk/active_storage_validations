# frozen_string_literal: true

class AspectRatio::Validator::AsvErrorable < ApplicationRecord
  has_one_attached :asv_errorable
  validates :asv_errorable, aspect_ratio: :square
end
