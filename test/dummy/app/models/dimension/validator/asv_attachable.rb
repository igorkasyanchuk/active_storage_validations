# frozen_string_literal: true

class Dimension::Validator::AsvAttachable < ApplicationRecord
  has_one_attached :asv_attachable
  has_many_attached :asv_attachables
  validates :asv_attachables, dimension: { width: 150, height: 150 }
  validates :asv_attachable, dimension: { width: 150, height: 150 }
end
