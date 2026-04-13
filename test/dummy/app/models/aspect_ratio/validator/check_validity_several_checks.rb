# frozen_string_literal: true

# == Schema Information
#
# Table name: aspect_ratio_validator_check_validity_several_checks
#
#  id         :integer          not null, primary key
#  created_at :datetime         not null
#  updated_at :datetime         not null
#

class AspectRatio::Validator::CheckValiditySeveralChecks < ApplicationRecord
  has_one_attached :invalid
  validates :invalid, aspect_ratio: { with: :square, in: %w[square portrait landscape] }
end
