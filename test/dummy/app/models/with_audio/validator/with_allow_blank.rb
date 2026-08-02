# frozen_string_literal: true

class WithAudio::Validator::WithAllowBlank < ApplicationRecord
  has_one_attached :with_allow_blank
  validates :with_allow_blank, with_audio: true, allow_blank: true
end
