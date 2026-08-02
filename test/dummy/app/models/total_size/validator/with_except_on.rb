# frozen_string_literal: true

# == Schema Information
#
# Table name: total_size_validator_with_except_ons
#
#  id         :integer          not null, primary key
#  created_at :datetime         not null
#  updated_at :datetime         not null
#

class TotalSize::Validator::WithExceptOn < ApplicationRecord
  has_many_attached :with_except_on
  validates :with_except_on, total_size: { less_than: 2.kilobytes }, except_on: :update
end
