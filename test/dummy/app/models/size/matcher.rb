# frozen_string_literal: true

# == Schema Information
#
# Table name: size_matchers
#
#  title      :string
#  id         :integer          not null, primary key
#  created_at :datetime         not null
#  updated_at :datetime         not null
#

class Size::Matcher < ApplicationRecord
  include Validatable

  has_one_attached :less_than
  has_one_attached :less_than_or_equal_to
  has_one_attached :greater_than
  has_one_attached :greater_than_or_equal_to
  has_one_attached :between
  validates :less_than, size: { less_than: 2.kilobytes }
  validates :less_than_or_equal_to, size: { less_than_or_equal_to: 2.kilobytes }
  validates :greater_than, size: { greater_than: 7.kilobytes }
  validates :greater_than_or_equal_to, size: { greater_than_or_equal_to: 7.kilobytes }
  validates :between, size: { between: 2.kilobytes..7.kilobytes }

  has_one_attached :proc_less_than
  has_one_attached :proc_less_than_or_equal_to
  has_one_attached :proc_greater_than
  has_one_attached :proc_greater_than_or_equal_to
  has_one_attached :proc_between
  validates :proc_less_than, size: { less_than: -> (record) { 2.kilobytes } }
  validates :proc_less_than_or_equal_to, size: { less_than_or_equal_to: -> (record) { 2.kilobytes } }
  validates :proc_greater_than, size: { greater_than: -> (record) { 7.kilobytes } }
  validates :proc_greater_than_or_equal_to, size: { greater_than_or_equal_to: -> (record) { 7.kilobytes } }
  validates :proc_between, size: { between: -> { 2.kilobytes..7.kilobytes } }

  has_one_attached :allow_blank
  validates :allow_blank, size: { less_than_or_equal_to: 5.megabytes }, allow_blank: true

  has_one_attached :with_message
  validates :with_message, size: { less_than_or_equal_to: 5.megabytes, message: 'Custom message' }

  has_one_attached :with_context_symbol
  validates :with_context_symbol, size: { less_than_or_equal_to: 5.megabytes }, on: :update
  has_one_attached :with_context_array
  validates :with_context_array, size: { less_than_or_equal_to: 5.megabytes }, on: %i[update custom]
  has_one_attached :with_several_validators_and_contexts
  validates :with_several_validators_and_contexts, size: { less_than_or_equal_to: 5.megabytes }, on: :update
  validates :with_several_validators_and_contexts, size: { less_than_or_equal_to: 5.megabytes }, on: :custom

  has_one_attached :as_instance
  validates :as_instance, size: { less_than_or_equal_to: 5.megabytes }

  has_one_attached :validatable_different_error_messages
  validates :validatable_different_error_messages, size: { less_than: 20.megabytes, message: 'Custom message 1' }, if: :title_is_quo_vadis?
  validates :validatable_different_error_messages, size: { less_than: 10.megabytes, message: 'Custom message 2' }, if: :title_is_american_psycho?

  has_one_attached :failure_message
  validates :failure_message, size: { less_than_or_equal_to: 5.megabytes }
  has_one_attached :failure_message_when_negated
  validates :failure_message_when_negated, size: { less_than_or_equal_to: 5.megabytes }

  # Combinations
  has_one_attached :less_than_with_message
  has_one_attached :less_than_or_equal_to_with_message
  has_one_attached :greater_than_with_message
  has_one_attached :greater_than_or_equal_to_with_message
  has_one_attached :between_with_message
  validates :less_than_with_message, size: { less_than: 2.kilobytes, message: 'File is too big.' }
  validates :less_than_or_equal_to_with_message, size: { less_than_or_equal_to: 2.kilobytes, message: 'File is too big.' }
  validates :greater_than_with_message, size: { greater_than: 7.kilobytes, message: 'File is too small.' }
  validates :greater_than_or_equal_to_with_message, size: { greater_than_or_equal_to: 7.kilobytes, message: 'File is too small.' }
  validates :between_with_message, size: { between: 2.kilobytes..7.kilobytes, message: 'File is not in accepted size range.' }
end
