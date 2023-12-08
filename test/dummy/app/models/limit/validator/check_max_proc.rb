# frozen_string_literal: true

# == Schema Information
#
# Table name: limit_validator_check_max_procs
#
#  id         :integer          not null, primary key
#  created_at :datetime         not null
#  updated_at :datetime         not null
#

class Limit::Validator::CheckMaxProc < ApplicationRecord
  has_many_attached :max_proc
  validates :max_proc, limit: { max: -> (record) { 1 } }
end
