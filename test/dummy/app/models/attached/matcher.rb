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
  include Validatable

  has_one_attached :required
  validates :required, attached: true

  has_one_attached :with_message
  validates :with_message, attached: { message: 'Custom message' }

  has_one_attached :with_context_symbol
  validates :with_context_symbol, attached: true, on: :update
  has_one_attached :with_context_array
  validates :with_context_array, attached: true, on: %i[update custom]
  has_one_attached :with_several_validators_and_contexts
  validates :with_several_validators_and_contexts, attached: true, on: :update
  validates :with_several_validators_and_contexts, attached: true, on: :custom

  has_one_attached :as_instance
  validates :as_instance, attached: true

  has_one_attached :validatable_different_error_messages
  validates :validatable_different_error_messages, attached: { message: 'Custom message 1' }, if: :title_is_quo_vadis?
  validates :validatable_different_error_messages, attached: { message: 'Custom message 2' }, if: :title_is_american_psycho?

  has_one_attached :failure_message
  validates :failure_message, attached: true
  has_one_attached :failure_message_when_negated
  validates :failure_message_when_negated, attached: true

  has_one_attached :not_required
end
