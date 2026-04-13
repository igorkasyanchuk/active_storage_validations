# frozen_string_literal: true

# == Schema Information
#
# Table name: attachment_validator_with_unlesses
#
#  rating     :integer
#  id         :integer          not null, primary key
#  created_at :datetime         not null
#  updated_at :datetime         not null
#

class Attachment::Validator::WithUnless < ApplicationRecord
  has_one_attached :with_unless
  has_one_attached :with_unless_proc
  validate_attached :with_unless, aspect_ratio: :square, size: { less_than: 1.megabyte }, unless: :rating_is_good?
  validate_attached :with_unless_proc, aspect_ratio: :square, size: { less_than: 1.megabyte }, unless: -> { self.rating == 0 }

  def rating_is_good?
    rating >= 4
  end
end
