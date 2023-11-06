# frozen_string_literal: true

# == Schema Information
#
# Table name: size_zero_validators
#
#  id         :integer          not null, primary key
#  title      :string
#  created_at :datetime         not null
#  updated_at :datetime         not null
#

class Size::ZeroValidator < ApplicationRecord
  has_one_attached :zero_size_validator

  validates :title, presence: true

  validates :zero_size_validator, size: {}
end
