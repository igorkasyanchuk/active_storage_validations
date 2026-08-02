# frozen_string_literal: true

# == Schema Information
#
# Table name: processable_file_matchers
#
#  title      :string
#  id         :integer          not null, primary key
#  created_at :datetime         not null
#  updated_at :datetime         not null
#

class ProcessableFile::Matcher < ApplicationRecord
  include Validatable

  has_one_attached :custom_matcher
  validates :custom_matcher, processable_file: true

  has_one_attached :processable
  validates :processable, processable_file: true

  has_one_attached :with_message
  validates :with_message, processable_file: { message: "Custom message" }

  has_one_attached :with_context_symbol
  validates :with_context_symbol, processable_file: true, on: :update
  has_one_attached :with_context_array
  validates :with_context_array, processable_file: true, on: %i[update custom]
  has_one_attached :with_several_validators_and_contexts
  validates :with_several_validators_and_contexts, processable_file: true, on: :update
  validates :with_several_validators_and_contexts, processable_file: true, on: :custom

  if Rails.gem_version >= Gem::Version.new("8.0.0")
    has_one_attached :with_except_on_symbol
    validates :with_except_on_symbol, processable_file: true, except_on: :update
    has_one_attached :with_except_on_array
    validates :with_except_on_array, processable_file: true, except_on: %i[update custom]
    has_one_attached :with_several_validators_and_except_on
    validates :with_several_validators_and_except_on, processable_file: true, except_on: :update
    validates :with_several_validators_and_except_on, processable_file: true, except_on: :custom
  end

  has_one_attached :as_instance
  validates :as_instance, processable_file: true

  has_one_attached :validatable_different_error_messages
  validates :validatable_different_error_messages, processable_file: { message: "Custom message 1" }, if: :title_is_quo_vadis?
  validates :validatable_different_error_messages, processable_file: { message: "Custom message 2" }, if: :title_is_american_psycho?

  has_one_attached :failure_message
  validates :failure_message, processable_file: true
  has_one_attached :failure_message_when_negated
  validates :failure_message_when_negated, processable_file: true

  has_one_attached :not_processable
end
