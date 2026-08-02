# frozen_string_literal: true

# == Schema Information
#
# Table name: duration_validator_with_except_ons
#
#  id         :integer          not null, primary key
#  created_at :datetime         not null
#  updated_at :datetime         not null
#

class Duration::Validator::WithExceptOn < ApplicationRecord
  has_one_attached :with_except_on
  validates :with_except_on, duration: { less_than: 2.seconds }, except_on: :update
end
