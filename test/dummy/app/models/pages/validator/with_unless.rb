# frozen_string_literal: true

# == Schema Information
#
# Table name: pages_validator_with_unlesses
#
#  rating     :integer
#  id         :integer          not null, primary key
#  created_at :datetime         not null
#  updated_at :datetime         not null
#

class Pages::Validator::WithUnless < ApplicationRecord
  has_one_attached :with_unless
  has_one_attached :with_unless_proc
  validates :with_unless, pages: { equal_to: 5 }, unless: :rating_is_good?
  validates :with_unless_proc, pages: { equal_to: 5 }, unless: -> { self.rating == 0 }

  def rating_is_good?
    rating >= 4
  end
end
