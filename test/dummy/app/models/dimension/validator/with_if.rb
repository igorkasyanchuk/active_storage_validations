# frozen_string_literal: true

# == Schema Information
#
# Table name: dimension_validator_with_ifs
#
#  title      :string
#  id         :integer          not null, primary key
#  created_at :datetime         not null
#  updated_at :datetime         not null
#

class Dimension::Validator::WithIf < ApplicationRecord
  has_one_attached :with_if
  validates :with_if, dimension: { width: 150, height: 150 }, if: -> { self.title == 'Right title' }
end
