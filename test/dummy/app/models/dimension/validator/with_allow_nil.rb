# frozen_string_literal: true

# == Schema Information
#
# Table name: dimension_validator_with_allow_nils
#
#  id         :integer          not null, primary key
#  created_at :datetime         not null
#  updated_at :datetime         not null
#

class Dimension::Validator::WithAllowNil < ApplicationRecord
  has_one_attached :with_allow_nil
  validates :with_allow_nil, dimension: { width: 150, height: 150 }, allow_nil: true
end
