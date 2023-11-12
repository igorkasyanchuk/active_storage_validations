# frozen_string_literal: true

# == Schema Information
#
# Table name: processable_image_validators
#
#  id         :integer          not null, primary key
#  created_at :datetime         not null
#  updated_at :datetime         not null
#

class ProcessableImage::Validator < ApplicationRecord
  has_one_attached :with_context
  validates :with_context, processable_image: true, on: %i(create update destroy custom)
end
