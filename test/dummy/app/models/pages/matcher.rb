# frozen_string_literal: true

# == Schema Information
#
# Table name: pages_matchers
#
#  title      :string
#  id         :integer          not null, primary key
#  created_at :datetime         not null
#  updated_at :datetime         not null
#

class Pages::Matcher < ApplicationRecord
  include Validatable

  has_one_attached :custom_matcher
  validates :custom_matcher, pages: { equal_to: 5 }

  has_one_attached :less_than
  has_one_attached :less_than_or_equal_to
  has_one_attached :greater_than
  has_one_attached :greater_than_or_equal_to
  has_one_attached :between
  has_one_attached :equal_to
  has_many_attached :many_greater_than
  validates :less_than, pages: { less_than: 2 }
  validates :less_than_or_equal_to, pages: { less_than_or_equal_to: 2 }
  validates :greater_than, pages: { greater_than: 7 }
  validates :greater_than_or_equal_to, pages: { greater_than_or_equal_to: 7 }
  validates :between, pages: { between: 2..7 }
  validates :equal_to, pages: { equal_to: 5 }
  validates :many_greater_than, pages: { greater_than: 7 }

  has_one_attached :proc_less_than
  has_one_attached :proc_less_than_or_equal_to
  has_one_attached :proc_greater_than
  has_one_attached :proc_greater_than_or_equal_to
  has_one_attached :proc_between
  has_one_attached :proc_equal_to
  has_many_attached :proc_many_greater_than
  validates :proc_less_than, pages: { less_than: ->(record) { 2 } }
  validates :proc_less_than_or_equal_to, pages: { less_than_or_equal_to: ->(record) { 2 } }
  validates :proc_greater_than, pages: { greater_than: ->(record) { 7 } }
  validates :proc_greater_than_or_equal_to, pages: { greater_than_or_equal_to: ->(record) { 7 } }
  validates :proc_between, pages: { between: -> { 2..7 } }
  validates :proc_equal_to, pages: { equal_to: ->(record) { 5 } }
  validates :proc_many_greater_than, pages: { greater_than: ->(record) { 7 } }

  has_one_attached :allow_blank
  validates :allow_blank, pages: { less_than_or_equal_to: 5 }, allow_blank: true

  has_one_attached :with_message
  validates :with_message, pages: { less_than_or_equal_to: 5, message: "Custom message" }

  has_one_attached :with_context_symbol
  validates :with_context_symbol, pages: { less_than_or_equal_to: 5 }, on: :update
  has_one_attached :with_context_array
  validates :with_context_array, pages: { less_than_or_equal_to: 5 }, on: %i[update custom]
  has_one_attached :with_several_validators_and_contexts
  validates :with_several_validators_and_contexts, pages: { less_than_or_equal_to: 5 }, on: :update
  validates :with_several_validators_and_contexts, pages: { less_than_or_equal_to: 5 }, on: :custom

  has_one_attached :as_instance
  validates :as_instance, pages: { less_than_or_equal_to: 5 }

  has_one_attached :validatable_different_error_messages
  validates :validatable_different_error_messages, pages: { less_than: 20, message: "Custom message 1" }, if: :title_is_quo_vadis?
  validates :validatable_different_error_messages, pages: { less_than: 10, message: "Custom message 2" }, if: :title_is_american_psycho?

  has_one_attached :failure_message
  validates :failure_message, pages: { less_than_or_equal_to: 5 }
  has_one_attached :failure_message_when_negated
  validates :failure_message_when_negated, pages: { less_than_or_equal_to: 5 }

  # Combinations
  has_one_attached :less_than_with_message
  has_one_attached :less_than_or_equal_to_with_message
  has_one_attached :greater_than_with_message
  has_one_attached :greater_than_or_equal_to_with_message
  has_one_attached :between_with_message
  has_one_attached :equal_to_with_message
  validates :less_than_with_message, pages: { less_than: 2, message: "File has too many pages." }
  validates :less_than_or_equal_to_with_message, pages: { less_than_or_equal_to: 2, message: "File has too many pages." }
  validates :greater_than_with_message, pages: { greater_than: 7, message: "File does not have many pages." }
  validates :greater_than_or_equal_to_with_message, pages: { greater_than_or_equal_to: 7, message: "File does not have many pages." }
  validates :between_with_message, pages: { between: 2..7, message: "File does not have accepted range number of pages." }
  validates :equal_to_with_message, pages: { equal_to: 5, message: "File does not have accepted number of pages." }
end
