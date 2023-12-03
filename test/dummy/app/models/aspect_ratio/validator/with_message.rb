# frozen_string_literal: true

# == Schema Information
#
# Table name: aspect_ratio_validator_with_messages
#
#  id         :integer          not null, primary key
#  created_at :datetime         not null
#  updated_at :datetime         not null
#

class AspectRatio::Validator::WithMessage < ApplicationRecord
  has_one_attached :with_message
  validates :with_message, aspect_ratio: { with: :square , message: 'Custom message' }
end
