# frozen_string_literal: true

class Size::Validator::AsvAttachable < ApplicationRecord
  has_many_attached :asv_attachables
  validates :asv_attachables, size: { less_than_or_equal_to: 1.kilobyte }
end
