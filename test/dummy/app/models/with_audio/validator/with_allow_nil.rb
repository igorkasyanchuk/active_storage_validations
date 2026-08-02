# frozen_string_literal: true

class WithAudio::Validator::WithAllowNil < ApplicationRecord
  has_one_attached :with_allow_nil
  validates :with_allow_nil, with_audio: true, allow_nil: true
end
