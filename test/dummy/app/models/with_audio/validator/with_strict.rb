# frozen_string_literal: true

class WithAudio::Validator::WithStrict < ApplicationRecord
  class StrictException < StandardError; end

  has_one_attached :with_strict
  validates :with_strict, with_audio: true, strict: StrictException
end
