# frozen_string_literal: true

# == Schema Information
#
# Table name: dimension_validator_checks
#
#  id         :integer          not null, primary key
#  created_at :datetime         not null
#  updated_at :datetime         not null
#

class Dimension::Validator::Check < ApplicationRecord
  has_one_attached :with_invalid_media_file
  validates :with_invalid_media_file, dimension: { width: 150, height: 150 }
end
