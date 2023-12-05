# frozen_string_literal: true

# == Schema Information
#
# Table name: attached_validator_with_unlessess
#
#  rating     :integer
#  id         :integer          not null, primary key
#  created_at :datetime         not null
#  updated_at :datetime         not null
#

class Attached::Validator::WithUnless < ApplicationRecord
  has_one_attached :with_unless
  has_one_attached :with_unless_proc
  validates :with_unless, attached: true, unless: :rating_is_good?
  validates :with_unless_proc, attached: true, unless: -> { self.rating == 0 }

  def rating_is_good?
    rating >= 4
  end
end
