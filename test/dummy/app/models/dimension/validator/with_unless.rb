# frozen_string_literal: true

# == Schema Information
#
# Table name: dimension_validator_with_unlessss
#
#  rating     :integer
#  id         :integer          not null, primary key
#  created_at :datetime         not null
#  updated_at :datetime         not null
#

class Dimension::Validator::WithUnless < ApplicationRecord
  has_one_attached :with_unless
  has_one_attached :with_unless_proc
  validates :with_unless, dimension: { width: 150, height: 150 }, unless: :rating_is_good?
  validates :with_unless_proc, dimension: { width: 150, height: 150 }, unless: -> { self.rating == 0 }

  def rating_is_good?
    rating >= 4
  end
end
