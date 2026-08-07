# frozen_string_literal: true

class WithAudio::Validator::WithUnless < ApplicationRecord
  has_one_attached :with_unless
  has_one_attached :with_unless_proc
  validates :with_unless, with_audio: true, unless: :rating_is_good?
  validates :with_unless_proc, with_audio: true, unless: -> { self.rating == 0 }

  def rating_is_good?
    rating >= 4
  end
end
