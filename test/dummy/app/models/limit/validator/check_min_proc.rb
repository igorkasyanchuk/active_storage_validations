# frozen_string_literal: true

# == Schema Information
#
# Table name: limit_validator_check_min_procs
#
#  id         :integer          not null, primary key
#  created_at :datetime         not null
#  updated_at :datetime         not null
#

class Limit::Validator::CheckMinProc < ApplicationRecord
  has_many_attached :min_proc
  validates :min_proc, limit: { min: -> (record) { 2 } }
end
