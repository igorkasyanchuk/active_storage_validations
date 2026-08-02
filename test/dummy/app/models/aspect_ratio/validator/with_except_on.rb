# frozen_string_literal: true

# == Schema Information
#
# Table name: aspect_ratio_validator_with_except_ons
#
#  id         :integer          not null, primary key
#  created_at :datetime         not null
#  updated_at :datetime         not null
#

class AspectRatio::Validator::WithExceptOn < ApplicationRecord
  has_one_attached :with_except_on
  validates :with_except_on, aspect_ratio: :square, except_on: :update
end
