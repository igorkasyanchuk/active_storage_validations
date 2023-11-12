# frozen_string_literal: true

# == Schema Information
#
# Table name: aspect_ratio_validator_with_ifs
#
#  title      :string
#  id         :integer          not null, primary key
#  created_at :datetime         not null
#  updated_at :datetime         not null
#

class AspectRatio::Validator::WithIf < ApplicationRecord
  has_one_attached :with_if
  validates :with_if, aspect_ratio: :square, if: -> { self.title == 'Right title' }
end
