# frozen_string_literal: true

# == Schema Information
#
# Table name: attached_validator_with_ifs
#
#  title      :string
#  id         :integer          not null, primary key
#  created_at :datetime         not null
#  updated_at :datetime         not null
#

class Attached::Validator::WithIf < ApplicationRecord
  has_one_attached :with_if
  has_one_attached :with_if_proc
  validates :with_if, attached: true, if: :title_is_image?
  validates :with_if_proc, attached: true, if: -> { self.title == 'Right title' }

  def title_is_image?
    title == 'image'
  end
end
