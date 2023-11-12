# frozen_string_literal: true

# == Schema Information
#
# Table name: limit_validator_with_ifs
#
#  title      :string
#  id         :integer          not null, primary key
#  created_at :datetime         not null
#  updated_at :datetime         not null
#

class Limit::Validator::WithIf < ApplicationRecord
  has_one_attached :with_if
  validates :with_if, limit: { min: 1 }, if: -> { self.title == 'Right title' }
end
