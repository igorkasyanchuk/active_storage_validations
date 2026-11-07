# frozen_string_literal: true

class AspectRatio::Validator::AsvAttachable < ApplicationRecord
  has_one_attached :asv_attachable
  has_many_attached :asv_attachables
  validates :asv_attachables, aspect_ratio: :square
  validates :asv_attachable, aspect_ratio: :square
end
