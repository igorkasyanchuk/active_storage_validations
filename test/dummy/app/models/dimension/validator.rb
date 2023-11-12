# frozen_string_literal: true

# == Schema Information
#
# Table name: dimension_validators
#
#  id         :integer          not null, primary key
#  created_at :datetime         not null
#  updated_at :datetime         not null
#

class Dimension::Validator < ApplicationRecord
  has_one_attached :with_context
  validates :with_context, dimension: { width: 150, height: 150 }, on: %i(create update destroy custom)
end
