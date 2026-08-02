# frozen_string_literal: true

# == Schema Information
#
# Table name: pages_validator_with_except_ons
#
#  id         :integer          not null, primary key
#  created_at :datetime         not null
#  updated_at :datetime         not null
#

class Pages::Validator::WithExceptOn < ApplicationRecord
  has_one_attached :with_except_on
  validates :with_except_on, pages: { equal_to: 5 }, except_on: :update
end
