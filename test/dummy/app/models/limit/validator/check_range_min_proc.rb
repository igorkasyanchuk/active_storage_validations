# frozen_string_literal: true

# == Schema Information
#
# Table name: limit_validator_check_range_min_procs
#
#  id         :integer          not null, primary key
#  created_at :datetime         not null
#  updated_at :datetime         not null
#

class Limit::Validator::CheckRangeMinProc < ApplicationRecord
  has_many_attached :range_min_proc
  validates :range_min_proc, limit: { min: ->(_record) { 1 }, max: 3 }
end
