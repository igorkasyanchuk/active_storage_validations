# frozen_string_literal: true

# == Schema Information
#
# Table name: attached_validators
#
#  id         :integer          not null, primary key
#  created_at :datetime         not null
#  updated_at :datetime         not null
#

class Attached::Validator < ApplicationRecord
  has_one_attached :with_context
  validates :with_context, attached: true, on: %i(create update destroy custom)
end
