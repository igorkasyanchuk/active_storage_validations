# frozen_string_literal: true

# == Schema Information
#
# Table name: duration_validator_with_allow_blanks
#
#  id         :integer          not null, primary key
#  created_at :datetime         not null
#  updated_at :datetime         not null
#

class Duration::Validator::WithAllowBlank < ApplicationRecord
  has_one_attached :with_allow_blank
  validates :with_allow_blank, duration: { less_than: 2.seconds }, allow_blank: true
end
