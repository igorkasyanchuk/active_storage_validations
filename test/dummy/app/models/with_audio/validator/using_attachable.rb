# frozen_string_literal: true

class WithAudio::Validator::UsingAttachable < ApplicationRecord
  has_one_attached :using_attachable
  has_many_attached :using_attachables
  validates :using_attachable, with_audio: true
  validates :using_attachables, with_audio: true
end
