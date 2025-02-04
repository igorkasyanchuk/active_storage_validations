# frozen_string_literal: true

# == Schema Information
#
# Table name: total_size_matchers
#
#  title      :string
#  id         :integer          not null, primary key
#  created_at :datetime         not null
#  updated_at :datetime         not null
#

class TotalSize::Matcher < ApplicationRecord
  include Validatable

  has_many_attached :custom_matcher
  validates :custom_matcher, total_size: { less_than_or_equal_to: 5.megabytes }

  has_many_attached :less_than
  has_many_attached :less_than_or_equal_to
  has_many_attached :greater_than
  has_many_attached :greater_than_or_equal_to
  has_many_attached :between
  validates :less_than, total_size: { less_than: 2.kilobytes }
  validates :less_than_or_equal_to, total_size: { less_than_or_equal_to: 2.kilobytes }
  validates :greater_than, total_size: { greater_than: 7.kilobytes }
  validates :greater_than_or_equal_to, total_size: { greater_than_or_equal_to: 7.kilobytes }
  validates :between, total_size: { between: 2.kilobytes..7.kilobytes }

  has_many_attached :proc_less_than
  has_many_attached :proc_less_than_or_equal_to
  has_many_attached :proc_greater_than
  has_many_attached :proc_greater_than_or_equal_to
  has_many_attached :proc_between
  validates :proc_less_than, total_size: { less_than: ->(record) { 2.kilobytes } }
  validates :proc_less_than_or_equal_to, total_size: { less_than_or_equal_to: ->(record) { 2.kilobytes } }
  validates :proc_greater_than, total_size: { greater_than: ->(record) { 7.kilobytes } }
  validates :proc_greater_than_or_equal_to, total_size: { greater_than_or_equal_to: ->(record) { 7.kilobytes } }
  validates :proc_between, total_size: { between: -> { 2.kilobytes..7.kilobytes } }

  has_many_attached :allow_blank
  validates :allow_blank, total_size: { less_than_or_equal_to: 5.megabytes }, allow_blank: true

  has_many_attached :with_message
  validates :with_message, total_size: { less_than_or_equal_to: 5.megabytes, message: "Custom message" }

  has_many_attached :with_context_symbol
  validates :with_context_symbol, total_size: { less_than_or_equal_to: 5.megabytes }, on: :update
  has_many_attached :with_context_array
  validates :with_context_array, total_size: { less_than_or_equal_to: 5.megabytes }, on: %i[update custom]
  has_many_attached :with_several_validators_and_contexts
  validates :with_several_validators_and_contexts, total_size: { less_than_or_equal_to: 5.megabytes }, on: :update
  validates :with_several_validators_and_contexts, total_size: { less_than_or_equal_to: 5.megabytes }, on: :custom

  has_many_attached :as_instance
  validates :as_instance, total_size: { less_than_or_equal_to: 5.megabytes }

  has_many_attached :validatable_different_error_messages
  validates :validatable_different_error_messages, total_size: { less_than: 20.megabytes, message: "Custom message 1" }, if: :title_is_quo_vadis?
  validates :validatable_different_error_messages, total_size: { less_than: 10.megabytes, message: "Custom message 2" }, if: :title_is_american_psycho?

  has_many_attached :failure_message
  validates :failure_message, total_size: { less_than_or_equal_to: 5.megabytes }
  has_many_attached :failure_message_when_negated
  validates :failure_message_when_negated, total_size: { less_than_or_equal_to: 5.megabytes }

  # Combinations
  has_many_attached :less_than_with_message
  has_many_attached :less_than_or_equal_to_with_message
  has_many_attached :greater_than_with_message
  has_many_attached :greater_than_or_equal_to_with_message
  has_many_attached :between_with_message
  validates :less_than_with_message, total_size: { less_than: 2.kilobytes, message: "Total file size is too big." }
  validates :less_than_or_equal_to_with_message, total_size: { less_than_or_equal_to: 2.kilobytes, message: "Total file size is too big." }
  validates :greater_than_with_message, total_size: { greater_than: 7.kilobytes, message: "Total file size is too small." }
  validates :greater_than_or_equal_to_with_message, total_size: { greater_than_or_equal_to: 7.kilobytes, message: "Total file size is too small." }
  validates :between_with_message, total_size: { between: 2.kilobytes..7.kilobytes, message: "Total file size is not in accepted size range." }
end
