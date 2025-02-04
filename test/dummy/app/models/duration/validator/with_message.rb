# frozen_string_literal: true

# == Schema Information
#
# Table name: duration_validator_with_messages
#
#  id         :integer          not null, primary key
#  created_at :datetime         not null
#  updated_at :datetime         not null
#

class Duration::Validator::WithMessage < ApplicationRecord
  has_one_attached :with_message
  validates :with_message, duration: { less_than: 2.seconds, message: "Custom message" }
end
