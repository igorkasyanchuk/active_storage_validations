# frozen_string_literal: true

# == Schema Information
#
# Table name: attached_validator_check_validity_allow_blank_options
#
#  id         :integer          not null, primary key
#  created_at :datetime         not null
#  updated_at :datetime         not null
#

class Attached::Validator::CheckValidityAllowBlankOption < ApplicationRecord
  has_one_attached :invalid
  validates :invalid, attached: true, allow_blank: true
end
