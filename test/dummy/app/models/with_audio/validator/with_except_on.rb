# frozen_string_literal: true

class WithAudio::Validator::WithExceptOn < ApplicationRecord
  has_one_attached :with_except_on
  validates :with_except_on, with_audio: true, except_on: :update
end
