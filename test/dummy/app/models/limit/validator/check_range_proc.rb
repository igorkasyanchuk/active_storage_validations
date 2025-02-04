# frozen_string_literal: true

# == Schema Information
#
# Table name: limit_validator_check_range_procs
#
#  id         :integer          not null, primary key
#  created_at :datetime         not null
#  updated_at :datetime         not null
#

class Limit::Validator::CheckRangeProc < ApplicationRecord
  has_many_attached :range_proc
  validates :range_proc, limit: { min: ->(record) { 1 }, max: ->(record) { 3 } }
end
