# frozen_string_literal: true

class TotalSize::Validator::AsvAttachable < ApplicationRecord
  has_many_attached :asv_attachables
  validates :asv_attachables, total_size: { less_than_or_equal_to: 5.kilobytes } # Since we have many files
end
