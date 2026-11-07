# frozen_string_literal: true

class Pages::Validator::AsvAttachable < ApplicationRecord
  has_one_attached :asv_attachable
  has_many_attached :asv_attachables
  validates :asv_attachables, pages: { less_than_or_equal_to: 5 }
  validates :asv_attachable, pages: { less_than_or_equal_to: 5 }
end
