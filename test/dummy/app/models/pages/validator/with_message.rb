# frozen_string_literal: true

# == Schema Information
#
# Table name: pages_validator_with_messages
#
#  id         :integer          not null, primary key
#  created_at :datetime         not null
#  updated_at :datetime         not null
#

class Pages::Validator::WithMessage < ApplicationRecord
  has_one_attached :with_message
  validates :with_message, pages: { equal_to: 5, message: "Custom message" }
end
