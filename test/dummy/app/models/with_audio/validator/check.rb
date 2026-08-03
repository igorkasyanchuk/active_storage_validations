# frozen_string_literal: true

class WithAudio::Validator::Check < ApplicationRecord
  has_one_attached :video
  validates :video, with_audio: true

  has_one_attached :silent_video
  validates :silent_video, with_audio: { with: false }
end
