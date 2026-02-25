# frozen_string_literal: true

class Pages::Validator::AsvErrorable < ApplicationRecord
  has_one_attached :asv_errorable
  validates :asv_errorable, pages: { equal_to: 5 }
end
