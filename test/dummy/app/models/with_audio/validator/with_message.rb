# frozen_string_literal: true

class WithAudio::Validator::WithMessage < ApplicationRecord
  has_one_attached :with_message
  validates :with_message, with_audio: { message: "Custom message" }
end
