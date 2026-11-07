# frozen_string_literal: true

class WithAudio::Validator::AsvAttachable < ApplicationRecord
  has_one_attached :asv_attachable
  has_many_attached :asv_attachables
  validates :asv_attachables, with_audio: true
  validates :asv_attachable, with_audio: true
end
