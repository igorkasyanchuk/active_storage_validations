# frozen_string_literal: true

# == Schema Information
#
# Table name: total_size_validator_with_allow_nils
#
#  id         :integer          not null, primary key
#  created_at :datetime         not null
#  updated_at :datetime         not null
#

class TotalSize::Validator::WithAllowNil < ApplicationRecord
  has_many_attached :with_allow_nil
  validates :with_allow_nil, total_size: { less_than: 2.kilobytes }, allow_nil: true
end
