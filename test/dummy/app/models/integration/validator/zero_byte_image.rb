# frozen_string_literal: true

# == Schema Information
#
# Table name: integration_validator_zero_byte_images
#
#  id         :integer          not null, primary key
#  created_at :datetime         not null
#  updated_at :datetime         not null
#

class Integration::Validator::ZeroByteImage < ApplicationRecord
  has_one_attached :zero_byte_image
  validates :zero_byte_image, attached: true,
                              content_type: :png,
                              processable_image: true
end
