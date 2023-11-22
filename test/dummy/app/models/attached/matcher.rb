# frozen_string_literal: true

# == Schema Information
#
# Table name: attached_matchers
#
#  id         :integer          not null, primary key
#  created_at :datetime         not null
#  updated_at :datetime         not null
#

class Attached::Matcher < ApplicationRecord
  has_one_attached :required
  validates :required, attached: true

  has_one_attached :required_with_message
  validates :required_with_message, attached: { message: 'Mandatory.' }

  has_one_attached :with_context_symbol
  validates :with_context_symbol, attached: true, on: :update
  has_one_attached :with_context_array
  validates :with_context_array, attached: true, on: %i[update custom]

  has_one_attached :not_required
end
