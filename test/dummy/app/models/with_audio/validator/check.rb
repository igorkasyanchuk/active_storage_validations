# frozen_string_literal: true

class WithAudio::Validator::Check < ApplicationRecord
  has_one_attached :video
  validates :video, with_audio: true
end
