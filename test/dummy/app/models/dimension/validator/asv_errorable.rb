# frozen_string_literal: true

class Dimension::Validator::AsvErrorable < ApplicationRecord
  has_one_attached :asv_errorable
  validates :asv_errorable, dimension: { width: 150, height: 150 }
end
