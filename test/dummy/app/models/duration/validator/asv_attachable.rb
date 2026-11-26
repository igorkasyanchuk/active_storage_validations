# frozen_string_literal: true

class Duration::Validator::AsvAttachable < ApplicationRecord
  has_one_attached :asv_attachable
  has_many_attached :asv_attachables
  validates :asv_attachables, duration: { less_than_or_equal_to: 2.seconds }
  validates :asv_attachable, duration: { less_than_or_equal_to: 2.seconds }
end
