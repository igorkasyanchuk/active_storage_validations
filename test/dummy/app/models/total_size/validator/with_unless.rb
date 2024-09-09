# frozen_string_literal: true

# == Schema Information
#
# Table name: total_size_validator_with_unlesses
#
#  rating     :integer
#  id         :integer          not null, primary key
#  created_at :datetime         not null
#  updated_at :datetime         not null
#

class TotalSize::Validator::WithUnless < ApplicationRecord
  has_many_attached :with_unless
  has_many_attached :with_unless_proc
  validates :with_unless, total_size: { less_than: 2.kilobytes }, unless: :rating_is_good?
  validates :with_unless_proc, total_size: { less_than: 2.kilobytes }, unless: -> { self.rating == 0 }

  def rating_is_good?
    rating >= 4
  end
end
