# frozen_string_literal: true

# == Schema Information
#
# Table name: content_type_matchers
#
#  id         :integer          not null, primary key
#  created_at :datetime         not null
#  updated_at :datetime         not null
#

class ContentType::Matcher < ApplicationRecord
  has_one_attached :allowing_one
  validates :allowing_one, content_type: :png
  has_one_attached :allowing_several
  validates :allowing_several, content_type: ['image/png', 'image/gif']
  has_one_attached :allowing_several_through_regex
  validates :allowing_several_through_regex, content_type: [/\Aimage\/.*\z/]

  has_one_attached :with_message
  validates :with_message, content_type: { in: ['image/png'], message: 'Not authorized file type.' }

  has_one_attached :with_context_symbol
  validates :with_context_symbol, content_type: :png, on: :update
  has_one_attached :with_context_array
  validates :with_context_array, content_type: :png, on: %i[update custom]

  # Combinations
  has_one_attached :allowing_one_with_message
  validates :allowing_one_with_message, content_type: { in: ['file/pdf'], message: 'Not authorized file type.' }
end
