# frozen_string_literal: true

# == Schema Information
#
# Table name: processable_image_validator_checks
#
#  id         :integer          not null, primary key
#  created_at :datetime         not null
#  updated_at :datetime         not null
#

class ProcessableImage::Validator::Check < ApplicationRecord
  has_one_attached :has_to_be_processable
  validates :has_to_be_processable, processable_image: true
end
