# frozen_string_literal: true

# == Schema Information
#
# Table name: limit_validator_with_except_ons
#
#  id         :integer          not null, primary key
#  created_at :datetime         not null
#  updated_at :datetime         not null
#

class Limit::Validator::WithExceptOn < ApplicationRecord
  has_one_attached :with_except_on
  validates :with_except_on, limit: { min: 1 }, except_on: :update
end
