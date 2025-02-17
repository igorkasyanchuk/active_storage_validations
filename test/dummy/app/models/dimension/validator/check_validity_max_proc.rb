# frozen_string_literal: true

# == Schema Information
#
# Table name: dimension_validator_check_validity_max_procs
#
#  id         :integer          not null, primary key
#  created_at :datetime         not null
#  updated_at :datetime         not null
#

class Dimension::Validator::CheckValidityMaxProc < ApplicationRecord
  has_one_attached :invalid
  validates :invalid, dimension: { max: -> { 15 } }
end
