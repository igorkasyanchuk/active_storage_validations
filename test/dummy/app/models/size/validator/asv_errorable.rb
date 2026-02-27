# frozen_string_literal: true

class Size::Validator::AsvErrorable < ApplicationRecord
  has_one_attached :asv_errorable
  validates :asv_errorable, size: { less_than: 2.kilobytes }
end
