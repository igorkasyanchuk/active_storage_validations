# frozen_string_literal: true

# == Schema Information
#
# Table name: aspect_ratio_validator_with_unlesses
#
#  rating     :integer
#  id         :integer          not null, primary key
#  created_at :datetime         not null
#  updated_at :datetime         not null
#

class AspectRatio::Validator::WithUnless < ApplicationRecord
  has_one_attached :with_unless
  has_one_attached :with_unless_proc
  validates :with_unless, aspect_ratio: :square, unless: :rating_is_good?
  validates :with_unless_proc, aspect_ratio: :square, unless: -> { self.rating == 0 }

  def rating_is_good?
    rating >= 4
  end
end
