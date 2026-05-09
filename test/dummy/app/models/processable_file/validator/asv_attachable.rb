# frozen_string_literal: true

class ProcessableFile::Validator::AsvAttachable < ApplicationRecord
  has_many_attached :asv_attachables
  validates :asv_attachables, processable_file: true
end
