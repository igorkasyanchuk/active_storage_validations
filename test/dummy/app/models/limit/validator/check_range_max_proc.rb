# frozen_string_literal: true

# == Schema Information
#
# Table name: limit_validator_check_range_max_procs
#
#  id         :integer          not null, primary key
#  created_at :datetime         not null
#  updated_at :datetime         not null
#

class Limit::Validator::CheckRangeMaxProc < ApplicationRecord
  has_many_attached :range_max_proc
  validates :range_max_proc, limit: { min: 1, max: ->(_record) { 3 } }
end
