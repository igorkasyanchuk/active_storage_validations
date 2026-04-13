# frozen_string_literal: true

# == Schema Information
#
# Table name: attachment_validator_with_messages
#
#  id         :integer          not null, primary key
#  created_at :datetime         not null
#  updated_at :datetime         not null
#

class Attachment::Validator::WithMessage < ApplicationRecord
  has_one_attached :with_message
  validate_attached :with_message, aspect_ratio: { with: :square, message: "Custom message" }, size: { less_than: 1.megabyte }
end
