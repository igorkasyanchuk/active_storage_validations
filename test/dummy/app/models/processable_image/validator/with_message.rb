# frozen_string_literal: true

# == Schema Information
#
# Table name: processable_image_validator_with_messages
#
#  id         :integer          not null, primary key
#  created_at :datetime         not null
#  updated_at :datetime         not null
#

class ProcessableImage::Validator::WithMessage < ApplicationRecord
  has_one_attached :with_message
  validates :with_message, processable_image: { message: 'Custom message' }
end
