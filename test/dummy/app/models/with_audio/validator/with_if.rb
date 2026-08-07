# frozen_string_literal: true

class WithAudio::Validator::WithIf < ApplicationRecord
  has_one_attached :with_if
  has_one_attached :with_if_proc
  validates :with_if, with_audio: true, if: :title_is_image?
  validates :with_if_proc, with_audio: true, if: -> { self.title == "Right title" }

  def title_is_image?
    title == "image"
  end
end
