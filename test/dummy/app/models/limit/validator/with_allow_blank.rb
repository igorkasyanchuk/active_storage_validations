# frozen_string_literal: true

# == Schema Information
#
# Table name: limit_validator_with_allow_blanks
#
#  id         :integer          not null, primary key
#  created_at :datetime         not null
#  updated_at :datetime         not null
#

class Limit::Validator::WithAllowBlank < ApplicationRecord
  has_one_attached :with_allow_blank
  validates :with_allow_blank, limit: { max: 0 }, allow_blank: true
end
