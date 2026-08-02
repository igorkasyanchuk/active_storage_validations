# frozen_string_literal: true

class WithAudio::Matcher < ApplicationRecord
  include Validatable

  has_one_attached :custom_matcher
  validates :custom_matcher, with_audio: true

  has_one_attached :with_audio
  validates :with_audio, with_audio: true

  has_one_attached :allow_blank
  validates :allow_blank, with_audio: true, allow_blank: true

  has_one_attached :with_message
  validates :with_message, with_audio: { message: "Custom message" }

  has_one_attached :with_timeout
  validates :with_timeout, with_audio: { timeout: 5.seconds }

  has_one_attached :with_context_symbol
  validates :with_context_symbol, with_audio: true, on: :update
  has_one_attached :with_context_array
  validates :with_context_array, with_audio: true, on: %i[update custom]
  has_one_attached :with_several_validators_and_contexts
  validates :with_several_validators_and_contexts, with_audio: true, on: :update
  validates :with_several_validators_and_contexts, with_audio: true, on: :custom

  if Rails.gem_version >= Gem::Version.new("8.0.0")
    has_one_attached :with_except_on_symbol
    validates :with_except_on_symbol, with_audio: true, except_on: :update
    has_one_attached :with_except_on_array
    validates :with_except_on_array, with_audio: true, except_on: %i[update custom]
    has_one_attached :with_several_validators_and_except_on
    validates :with_several_validators_and_except_on, with_audio: true, except_on: :update
    validates :with_several_validators_and_except_on, with_audio: true, except_on: :custom
  end

  has_one_attached :as_instance
  validates :as_instance, with_audio: true

  has_one_attached :validatable_different_error_messages
  validates :validatable_different_error_messages, with_audio: { message: "Custom message 1" }, if: :title_is_quo_vadis?
  validates :validatable_different_error_messages, with_audio: { message: "Custom message 2" }, if: :title_is_american_psycho?

  has_one_attached :failure_message
  validates :failure_message, with_audio: true
  has_one_attached :failure_message_when_negated
  validates :failure_message_when_negated, with_audio: true

  has_one_attached :without_audio
end
