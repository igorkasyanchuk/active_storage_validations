# frozen_string_literal: true

# == Schema Information
#
# Table name: size_validator_with_messages
#
#  id         :integer          not null, primary key
#  created_at :datetime         not null
#  updated_at :datetime         not null
#

class Size::Validator::WithMessage < ApplicationRecord
  has_one_attached :with_message
  validates :with_message, size: { less_than: 2.kilobytes , message: 'Custom message' }
end
