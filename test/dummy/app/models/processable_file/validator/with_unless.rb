# frozen_string_literal: true

# == Schema Information
#
# Table name: processable_file_validator_with_unlesses
#
#  rating     :integer
#  id         :integer          not null, primary key
#  created_at :datetime         not null
#  updated_at :datetime         not null
#

class ProcessableFile::Validator::WithUnless < ApplicationRecord
  has_one_attached :with_unless
  has_one_attached :with_unless_proc
  validates :with_unless, processable_file: true, unless: :rating_is_good?
  validates :with_unless_proc, processable_file: true, unless: -> { self.rating == 0 }

  def rating_is_good?
    rating >= 4
  end
end
