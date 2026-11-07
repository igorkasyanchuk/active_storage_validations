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
  has_one_attached :with_message_placeholders
  validates :with_message_placeholders, duration: { less_than: 2.seconds, message: "%{attribute} must be under %{max} (got %{duration})" }
  has_one_attached :with_message_raw_option
  validates :with_message_raw_option, duration: { less_than: 2.seconds, message: "must be under %{less_than}" }
end
