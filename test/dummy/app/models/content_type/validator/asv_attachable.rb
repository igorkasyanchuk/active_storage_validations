# frozen_string_literal: true

class ContentType::Validator::AsvAttachable < ApplicationRecord
  has_one_attached :asv_attachable
  has_many_attached :asv_attachables
  validates :asv_attachables, content_type: :webp
  validates :asv_attachable, content_type: :webp
end
