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
  has_one_attached :with_if_proc
  validates :with_if, dimension: { width: 150, height: 150 }, if: :title_is_image?
  validates :with_if_proc, dimension: { width: 150, height: 150 }, if: -> { self.title == 'Right title' }

  def title_is_image?
    title == 'image'
  end
end
