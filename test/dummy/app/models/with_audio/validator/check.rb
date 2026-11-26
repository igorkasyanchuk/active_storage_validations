# frozen_string_literal: true

class WithAudio::Validator::Check < ApplicationRecord
  has_one_attached :video
  validates :video, with_audio: true

  has_one_attached :silent_video
  validates :silent_video, with_audio: { with: false }

  has_one_attached :video_proc
  validates :video_proc, with_audio: { with: ->(_record) { true } }

  has_one_attached :silent_video_proc
  validates :silent_video_proc, with_audio: { with: ->(_record) { false } }
end
