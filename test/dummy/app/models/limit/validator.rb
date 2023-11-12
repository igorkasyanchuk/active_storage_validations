# frozen_string_literal: true

# == Schema Information
#
# Table name: limit_validators
#
#  id         :integer          not null, primary key
#  created_at :datetime         not null
#  updated_at :datetime         not null
#

class Limit::Validator < ApplicationRecord
  has_one_attached :with_context
  validates :with_context, limit: { min: 1 }, on: %i(create update destroy custom)
end
