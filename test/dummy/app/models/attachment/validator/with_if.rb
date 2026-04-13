# frozen_string_literal: true

# == Schema Information
#
# Table name: attachment_validator_with_ifs
#
#  title      :string
#  id         :integer          not null, primary key
#  created_at :datetime         not null
#  updated_at :datetime         not null
#

class Attachment::Validator::WithIf < ApplicationRecord
  has_one_attached :with_if
  has_one_attached :with_if_proc
  validate_attached :with_if, aspect_ratio: :square, size: { less_than: 1.megabyte }, if: :title_is_image?
  validate_attached :with_if_proc, aspect_ratio: :square, size: { less_than: 1.megabyte }, if: -> { self.title == "Right title" }

  def title_is_image?
    title == "image"
  end
end
