# frozen_string_literal: true

# == Schema Information
#
# Table name: size_zero_validator_procs
#
#  id         :integer          not null, primary key
#  title      :string
#  created_at :datetime         not null
#  updated_at :datetime         not null
#

class Size::ZeroValidatorProc < ApplicationRecord
  has_one_attached :proc_zero_size_validator

  validates :title, presence: true

  validates :proc_zero_size_validator, size: {}
end
