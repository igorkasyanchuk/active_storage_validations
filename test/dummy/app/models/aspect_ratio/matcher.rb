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
  ActiveStorageValidations::AspectRatioValidator::NAMED_ASPECT_RATIOS.each do |aspect_ratio|
    has_one_attached :"allowing_one_#{aspect_ratio}"
    validates :"allowing_one_#{aspect_ratio}", aspect_ratio: aspect_ratio
  end
  has_one_attached :allowing_one_is_x_y
  validates :allowing_one_is_x_y, aspect_ratio: :is_16_9

  has_one_attached :with_message
  validates :with_message, aspect_ratio: { with: :square, message: 'Custom message' }

  has_one_attached :with_context_symbol
  validates :with_context_symbol, aspect_ratio: :square, on: :update
  has_one_attached :with_context_array
  validates :with_context_array, aspect_ratio: :square, on: %i[update custom]

  has_one_attached :as_instance
  validates :as_instance, aspect_ratio: :square

  # Combinations
  has_one_attached :allowing_one_with_message
  validates :allowing_one_with_message, aspect_ratio: { with: :portrait, message: 'Not authorized aspect ratio.' }
end
