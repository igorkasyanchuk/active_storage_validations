# frozen_string_literal: true

class Duration::Validator::AsvErrorable < ApplicationRecord
  has_one_attached :asv_errorable
  validates :asv_errorable, duration: { less_than: 2.seconds }
end
