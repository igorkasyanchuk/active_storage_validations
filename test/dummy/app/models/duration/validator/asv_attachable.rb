# frozen_string_literal: true

class Duration::Validator::AsvAttachable < ApplicationRecord
  has_many_attached :asv_attachables
  validates :asv_attachables, duration: { less_than_or_equal_to: 1.second }
end
