# frozen_string_literal: true

# == Schema Information
#
# Table name: pages_validator_with_allow_blanks
#
#  id         :integer          not null, primary key
#  created_at :datetime         not null
#  updated_at :datetime         not null
#

class Pages::Validator::WithAllowBlank < ApplicationRecord
  has_one_attached :with_allow_blank
  validates :with_allow_blank, pages: { equal_to: 5 }, allow_blank: true
end
