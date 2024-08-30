# frozen_string_literal: true

# == Schema Information
#
# Table name: limit_matchers
#
#  title      :string
#  id         :integer          not null, primary key
#  created_at :datetime         not null
#  updated_at :datetime         not null
#

class Limit::Matcher < ApplicationRecord
  include Validatable

  has_many_attached :custom_matcher
  validates :custom_matcher, limit: { min: 1, max: 5 }

  has_many_attached :allow_blank
  validates :allow_blank, limit: { min: 1, max: 5 }, allow_blank: true

  has_many_attached :with_message
  has_many_attached :without_message
  validates :with_message, limit: { min: 1, max: 5, message: 'Custom message' }
  validates :without_message, limit: { min: 1, max: 5 }

  has_many_attached :with_context_symbol
  validates :with_context_symbol, limit: { min: 1, max: 5 }, on: :update
  has_many_attached :with_context_array
  validates :with_context_array, limit: { min: 1, max: 5 }, on: %i[update custom]
  has_many_attached :with_several_validators_and_contexts
  validates :with_several_validators_and_contexts, limit: { min: 1, max: 5 }, on: :update
  validates :with_several_validators_and_contexts, limit: { min: 1, max: 5 }, on: :custom

  has_many_attached :as_instance
  validates :as_instance, limit: { min: 1, max: 5 }

  has_many_attached :validatable_different_error_messages
  validates :validatable_different_error_messages, limit: { min: 1, message: 'Custom message 1' }, if: :title_is_quo_vadis?
  validates :validatable_different_error_messages, limit: { min: 1, message: 'Custom message 2' }, if: :title_is_american_psycho?

  has_many_attached :failure_message
  validates :failure_message, limit: { min: 1, max: 5 }
  has_many_attached :failure_message_when_negated
  validates :failure_message_when_negated, limit: { min: 1, max: 5 }

  has_many_attached :with_0_file
  validates :with_0_file, limit: { min: 0 }

  # Combinations
  has_many_attached :min_with_message
  validates :min_with_message, limit: { min: 1, message: 'Invalid limits.' }
  has_many_attached :max_with_message
  validates :max_with_message, limit: { max: 5, message: 'Invalid limits.' }
end
