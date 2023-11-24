# frozen_string_literal: true

# == Schema Information
#
# Table name: content_type_validator_with_messages
#
#  id         :integer          not null, primary key
#  created_at :datetime         not null
#  updated_at :datetime         not null
#

class ContentType::Validator::WithMessage < ApplicationRecord
  has_one_attached :with_message
  validates :with_message, content_type: { with: :webp, message: 'Custom message' }
end
