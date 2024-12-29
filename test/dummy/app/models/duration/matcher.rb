# frozen_string_literal: true

# == Schema Information
#
# Table name: duration_matchers
#
#  title      :string
#  id         :integer          not null, primary key
#  created_at :datetime         not null
#  updated_at :datetime         not null
#

class Duration::Matcher < ApplicationRecord
  include Validatable

  has_one_attached :custom_matcher
  validates :custom_matcher, duration: { less_than_or_equal_to: 5.minutes }

  has_one_attached :less_than
  has_one_attached :less_than_or_equal_to
  has_one_attached :greater_than
  has_one_attached :greater_than_or_equal_to
  has_one_attached :between
  has_many_attached :many_greater_than
  validates :less_than, duration: { less_than: 2.seconds }
  validates :less_than_or_equal_to, duration: { less_than_or_equal_to: 2.seconds }
  validates :greater_than, duration: { greater_than: 7.seconds }
  validates :greater_than_or_equal_to, duration: { greater_than_or_equal_to: 7.seconds }
  validates :between, duration: { between: 2.seconds..7.seconds }
  validates :many_greater_than, duration: { greater_than: 7.seconds }

  has_one_attached :proc_less_than
  has_one_attached :proc_less_than_or_equal_to
  has_one_attached :proc_greater_than
  has_one_attached :proc_greater_than_or_equal_to
  has_one_attached :proc_between
  has_many_attached :proc_many_greater_than
  validates :proc_less_than, duration: { less_than: -> (record) { 2.seconds } }
  validates :proc_less_than_or_equal_to, duration: { less_than_or_equal_to: -> (record) { 2.seconds } }
  validates :proc_greater_than, duration: { greater_than: -> (record) { 7.seconds } }
  validates :proc_greater_than_or_equal_to, duration: { greater_than_or_equal_to: -> (record) { 7.seconds } }
  validates :proc_between, duration: { between: -> { 2.seconds..7.seconds } }
  validates :proc_many_greater_than, duration: { greater_than: -> (record) { 7.seconds } }

  has_one_attached :allow_blank
  validates :allow_blank, duration: { less_than_or_equal_to: 5.minutes }, allow_blank: true

  has_one_attached :with_message
  validates :with_message, duration: { less_than_or_equal_to: 5.minutes, message: 'Custom message' }

  has_one_attached :with_context_symbol
  validates :with_context_symbol, duration: { less_than_or_equal_to: 5.minutes }, on: :update
  has_one_attached :with_context_array
  validates :with_context_array, duration: { less_than_or_equal_to: 5.minutes }, on: %i[update custom]
  has_one_attached :with_several_validators_and_contexts
  validates :with_several_validators_and_contexts, duration: { less_than_or_equal_to: 5.minutes }, on: :update
  validates :with_several_validators_and_contexts, duration: { less_than_or_equal_to: 5.minutes }, on: :custom

  has_one_attached :as_instance
  validates :as_instance, duration: { less_than_or_equal_to: 5.minutes }

  has_one_attached :validatable_different_error_messages
  validates :validatable_different_error_messages, duration: { less_than: 20.minutes, message: 'Custom message 1' }, if: :title_is_quo_vadis?
  validates :validatable_different_error_messages, duration: { less_than: 10.minutes, message: 'Custom message 2' }, if: :title_is_american_psycho?

  has_one_attached :failure_message
  validates :failure_message, duration: { less_than_or_equal_to: 5.minutes }
  has_one_attached :failure_message_when_negated
  validates :failure_message_when_negated, duration: { less_than_or_equal_to: 5.minutes }

  # Combinations
  has_one_attached :less_than_with_message
  has_one_attached :less_than_or_equal_to_with_message
  has_one_attached :greater_than_with_message
  has_one_attached :greater_than_or_equal_to_with_message
  has_one_attached :between_with_message
  validates :less_than_with_message, duration: { less_than: 2.seconds, message: 'File is too big.' }
  validates :less_than_or_equal_to_with_message, duration: { less_than_or_equal_to: 2.seconds, message: 'File is too big.' }
  validates :greater_than_with_message, duration: { greater_than: 7.seconds, message: 'File is too small.' }
  validates :greater_than_or_equal_to_with_message, duration: { greater_than_or_equal_to: 7.seconds, message: 'File is too small.' }
  validates :between_with_message, duration: { between: 2.seconds..7.seconds, message: 'File is not in accepted duration range.' }
end
