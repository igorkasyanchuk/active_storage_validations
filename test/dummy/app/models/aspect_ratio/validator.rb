# frozen_string_literal: true

# == Schema Information
#
# Table name: aspect_ratio_validators
#
#  id         :integer          not null, primary key
#  created_at :datetime         not null
#  updated_at :datetime         not null
#

class AspectRatio::Validator < ApplicationRecord
  has_one_attached :with_context
  validates :with_context, aspect_ratio: :square, on: %i(create update destroy custom)
end
