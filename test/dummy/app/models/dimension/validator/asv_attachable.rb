# frozen_string_literal: true

class Dimension::Validator::AsvAttachable < ApplicationRecord
  has_many_attached :asv_attachables
  validates :asv_attachables, dimension: { width: 150, height: 150 }
end
