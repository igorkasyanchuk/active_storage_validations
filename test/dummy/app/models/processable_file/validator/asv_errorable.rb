# frozen_string_literal: true

class ProcessableFile::Validator::AsvErrorable < ApplicationRecord
  has_one_attached :asv_errorable
  validates :asv_errorable, processable_file: true
end
