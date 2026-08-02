# frozen_string_literal: true

# == Schema Information
#
# Table name: size_validator_with_except_ons
#
#  id         :integer          not null, primary key
#  created_at :datetime         not null
#  updated_at :datetime         not null
#

class Size::Validator::WithExceptOn < ApplicationRecord
  has_one_attached :with_except_on
  validates :with_except_on, size: { less_than: 2.kilobytes }, except_on: :update
end
