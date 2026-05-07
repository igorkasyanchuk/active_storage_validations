# frozen_string_literal: true

class Pages::Validator::AsvAttachable < ApplicationRecord
  has_many_attached :asv_attachables
  validates :asv_attachables, pages: { less_than_or_equal_to: 5 }
end
