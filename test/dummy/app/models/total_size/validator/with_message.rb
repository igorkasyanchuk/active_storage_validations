# frozen_string_literal: true

# == Schema Information
#
# Table name: total_size_validator_with_messages
#
#  id         :integer          not null, primary key
#  created_at :datetime         not null
#  updated_at :datetime         not null
#

class TotalSize::Validator::WithMessage < ApplicationRecord
  has_many_attached :with_message
  validates :with_message, total_size: { less_than: 2.kilobytes , message: 'Custom message' }
end
