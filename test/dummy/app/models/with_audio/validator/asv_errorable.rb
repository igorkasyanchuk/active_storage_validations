# frozen_string_literal: true

class WithAudio::Validator::AsvErrorable < ApplicationRecord
  has_one_attached :asv_errorable
  validates :asv_errorable, with_audio: true
end
