# frozen_string_literal: true

class ProcessableFile::Validator::AsvAttachable < ApplicationRecord
  has_one_attached :asv_attachable
  has_many_attached :asv_attachables
  validates :asv_attachables, processable_file: true
  validates :asv_attachable, processable_file: true
end
