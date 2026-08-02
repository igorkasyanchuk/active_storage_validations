# frozen_string_literal: true

class WithAudio::Validator::WithOn < ApplicationRecord
  has_one_attached :with_on
  validates :with_on, with_audio: true, on: %i[create update destroy custom]
end
