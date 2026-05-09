# frozen_string_literal: true

class ContentType::Validator::AsvAttachable < ApplicationRecord
  has_many_attached :asv_attachables
  validates :asv_attachables, content_type: :webp
end
