# frozen_string_literal: true

class AspectRatio::Validator::AsvAttachable < ApplicationRecord
  has_many_attached :asv_attachables
  validates :asv_attachables, aspect_ratio: :square
end
