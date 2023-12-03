# frozen_string_literal: true

# == Schema Information
#
# Table name: processable_image_validator_with_unlesses
#
#  rating     :integer
#  id         :integer          not null, primary key
#  created_at :datetime         not null
#  updated_at :datetime         not null
#

class ProcessableImage::Validator::WithUnless < ApplicationRecord
  has_one_attached :with_unless
  has_one_attached :with_unless_proc
  validates :with_unless, processable_image: true, unless: :rating_is_good?
  validates :with_unless_proc, processable_image: true, unless: -> { self.rating == 0 }

  def rating_is_good?
    rating >= 4
  end
end
