# frozen_string_literal: true

class ContentType::Validator::AsvErrorable < ApplicationRecord
  has_one_attached :asv_errorable
  validates :asv_errorable, content_type: :webp
end
