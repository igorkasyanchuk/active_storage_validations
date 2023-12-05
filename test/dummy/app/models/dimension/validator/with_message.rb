# frozen_string_literal: true

# == Schema Information
#
# Table name: dimension_validator_with_messages
#
#  id         :integer          not null, primary key
#  created_at :datetime         not null
#  updated_at :datetime         not null
#

class Dimension::Validator::WithMessage < ApplicationRecord
  has_one_attached :with_message
  validates :with_message, dimension: { width: 150, height: 150, message: 'Custom message' }
end
