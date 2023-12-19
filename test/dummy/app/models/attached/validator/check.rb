# frozen_string_literal: true

# == Schema Information
#
# Table name: attached_validator_checks
#
#  id         :integer          not null, primary key
#  created_at :datetime         not null
#  updated_at :datetime         not null
#

class Attached::Validator::Check < ApplicationRecord
  has_one_attached :has_to_be_attached
  validates :has_to_be_attached, attached: true
end
