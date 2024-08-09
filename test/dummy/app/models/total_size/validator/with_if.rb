# frozen_string_literal: true

# == Schema Information
#
# Table name: total_size_validator_with_ifs
#
#  title      :string
#  id         :integer          not null, primary key
#  created_at :datetime         not null
#  updated_at :datetime         not null
#

class TotalSize::Validator::WithIf < ApplicationRecord
  has_many_attached :with_if
  has_many_attached :with_if_proc
  validates :with_if, total_size: { less_than: 2.kilobytes }, if: :title_is_image?
  validates :with_if_proc, total_size: { less_than: 2.kilobytes }, if: -> { self.title == 'Right title' }

  def title_is_image?
    title == 'image'
  end
end
