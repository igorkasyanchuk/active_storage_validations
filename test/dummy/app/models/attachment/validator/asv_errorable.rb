# frozen_string_literal: true

class Attachment::Validator::AsvErrorable < ApplicationRecord
  has_one_attached :asv_errorable
  validate_attached :asv_errorable, aspect_ratio: :square, size: { less_than: 1.megabyte }
end
