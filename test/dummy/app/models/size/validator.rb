# frozen_string_literal: true

# == Schema Information
#
# Table name: size_validators
#
#  id         :integer          not null, primary key
#  created_at :datetime         not null
#  updated_at :datetime         not null
#

class Size::Validator < ApplicationRecord
  has_one_attached :with_context
  validates :with_context, size: { less_than: 2.kilobytes }, on: %i(create update destroy custom)
end
