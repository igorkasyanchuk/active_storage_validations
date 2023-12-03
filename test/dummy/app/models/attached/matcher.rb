# frozen_string_literal: true

# == Schema Information
#
# Table name: attached_matchers
#
#  title      :string
#  id         :integer          not null, primary key
#  created_at :datetime         not null
#  updated_at :datetime         not null
#

class Attached::Matcher < ApplicationRecord
  has_one_attached :required
  validates :required, attached: true

  has_one_attached :with_message
  validates :with_message, attached: { message: 'Custom message' }

  has_one_attached :with_context_symbol
  validates :with_context_symbol, attached: true, on: :update
  has_one_attached :with_context_array
  validates :with_context_array, attached: true, on: %i[update custom]

  has_one_attached :as_instance
  validates :as_instance, attached: true

  has_one_attached :not_required
end
