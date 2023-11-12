# frozen_string_literal: true

# == Schema Information
#
# Table name: size_validator_with_ifs
#
#  title      :string
#  id         :integer          not null, primary key
#  created_at :datetime         not null
#  updated_at :datetime         not null
#

class Size::Validator::WithIf < ApplicationRecord
  has_one_attached :with_if
  validates :with_if, size: { less_than: 2.kilobytes }, if: -> { self.title == 'Right title' }
end
