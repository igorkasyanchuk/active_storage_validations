# frozen_string_literal: true

# == Schema Information
#
# Table name: attachment_validator_with_ons
#
#  id         :integer          not null, primary key
#  created_at :datetime         not null
#  updated_at :datetime         not null
#

class Attachment::Validator::WithOn < ApplicationRecord
  has_one_attached :with_on
  validate_attached :with_on, aspect_ratio: :square, size: { less_than: 1.megabyte }, on: %i[create update destroy custom]
end
