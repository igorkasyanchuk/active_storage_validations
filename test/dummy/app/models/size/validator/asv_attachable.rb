# frozen_string_literal: true

class Size::Validator::AsvAttachable < ApplicationRecord
  has_one_attached :asv_attachable
  has_many_attached :asv_attachables
  validates :asv_attachables, size: { less_than_or_equal_to: 1.kilobyte }
  validates :asv_attachable, size: { less_than_or_equal_to: 1.kilobyte }
end
