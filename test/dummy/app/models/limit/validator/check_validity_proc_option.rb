# frozen_string_literal: true

# == Schema Information
#
# Table name: limit_validator_check_validity_proc_options
#
#  id         :integer          not null, primary key
#  created_at :datetime         not null
#  updated_at :datetime         not null
#

class Limit::Validator::CheckValidityProcOption < ApplicationRecord
  has_one_attached :invalid_1
  has_one_attached :invalid_2
  has_one_attached :invalid_3
  has_one_attached :invalid_4
  has_one_attached :invalid_5
  validates :invalid_1, limit: { min: ->(record) { "invalid" } }
  validates :invalid_2, limit: { max: ->(record) { "invalid" } }
  validates :invalid_3, limit: { min: ->(record) { "invalid" }, max: ->(record) { "invalid" } }
  validates :invalid_4, limit: { min: 1, max: ->(record) { "invalid" } }
  validates :invalid_5, limit: { min: ->(record) { "invalid" }, max: 3 }
end
