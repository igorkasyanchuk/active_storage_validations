# frozen_string_literal: true

# == Schema Information
#
# Table name: dimension_validator_check_validity_dimension_in_procs
#
#  id         :integer          not null, primary key
#  created_at :datetime         not null
#  updated_at :datetime         not null
#

class Dimension::Validator::CheckValidityDimensionInProc < ApplicationRecord
  has_one_attached :valid
  validates :valid, dimension: { width: { in: ->(record) { 100..200 } } }
end
