# frozen_string_literal: true

# == Schema Information
#
# Table name: aspect_ratio_matchers
#
#  title      :string
#  id         :integer          not null, primary key
#  created_at :datetime         not null
#  updated_at :datetime         not null
#

class AspectRatio::Matcher < ApplicationRecord
  include Validatable

  ActiveStorageValidations::AspectRatioValidator::NAMED_ASPECT_RATIOS.each do |aspect_ratio|
    has_one_attached :"allowing_one_#{aspect_ratio}"
    validates :"allowing_one_#{aspect_ratio}", aspect_ratio: aspect_ratio
  end
  has_one_attached :allowing_one_is_x_y
  validates :allowing_one_is_x_y, aspect_ratio: :is_16_9

  has_one_attached :allow_blank
  validates :allow_blank, aspect_ratio: :square, allow_blank: true

  has_one_attached :with_message
  validates :with_message, aspect_ratio: { with: :square, message: 'Custom message' }

  has_one_attached :with_context_symbol
  validates :with_context_symbol, aspect_ratio: :square, on: :update
  has_one_attached :with_context_array
  validates :with_context_array, aspect_ratio: :square, on: %i[update custom]
  has_one_attached :with_several_validators_and_contexts
  validates :with_several_validators_and_contexts, aspect_ratio: :square, on: :update
  validates :with_several_validators_and_contexts, aspect_ratio: :square, on: :custom

  has_one_attached :as_instance
  validates :as_instance, aspect_ratio: :square

  has_one_attached :validatable_different_error_messages
  validates :validatable_different_error_messages, aspect_ratio: { with: :portrait, message: 'Custom message 1' }, if: :title_is_quo_vadis?
  validates :validatable_different_error_messages, aspect_ratio: { with: :square, message: 'Custom message 2' }, if: :title_is_american_psycho?

  has_one_attached :failure_message
  validates :failure_message, aspect_ratio: :square
  has_one_attached :failure_message_when_negated
  validates :failure_message_when_negated, aspect_ratio: :square

  # Combinations
  has_one_attached :allowing_one_with_message
  validates :allowing_one_with_message, aspect_ratio: { with: :portrait, message: 'Not authorized aspect ratio.' }
end
