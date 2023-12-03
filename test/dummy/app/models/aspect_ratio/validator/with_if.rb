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
  has_one_attached :with_if_proc
  validates :with_if, aspect_ratio: :square, if: :title_is_image?
  validates :with_if_proc, aspect_ratio: :square, if: -> { self.title == 'Right title' }

  def title_is_image?
    title == 'image'
  end
end
