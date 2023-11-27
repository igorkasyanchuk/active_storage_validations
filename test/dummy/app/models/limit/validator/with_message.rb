# frozen_string_literal: true

# == Schema Information
#
# Table name: limit_validator_with_messages
#
#  id         :integer          not null, primary key
#  created_at :datetime         not null
#  updated_at :datetime         not null
#

class Limit::Validator::WithMessage < ApplicationRecord
  has_one_attached :with_message
  validates :with_message, limit: { max: 0, message: 'Custom message' }
end
