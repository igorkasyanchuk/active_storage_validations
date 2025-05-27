# frozen_string_literal: true

# == Schema Information
#
# Table name: duration_validator_checks
#
#  id         :integer          not null, primary key
#  created_at :datetime         not null
#  updated_at :datetime         not null
#

class Duration::Validator::Check < ApplicationRecord
  has_one_attached :less_than
  has_one_attached :less_than_or_equal_to
  has_one_attached :greater_than
  has_one_attached :greater_than_or_equal_to
  has_one_attached :between
  has_one_attached :equal_to
  validates :less_than, duration: { less_than: 2.seconds }
  validates :less_than_or_equal_to, duration: { less_than_or_equal_to: 2.seconds }
  validates :greater_than, duration: { greater_than: 7.seconds }
  validates :greater_than_or_equal_to, duration: { greater_than_or_equal_to: 7.seconds }
  validates :between, duration: { between: 2.seconds..7.seconds }
  validates :equal_to, duration: { equal_to: 5.seconds }

  has_one_attached :less_than_proc
  has_one_attached :less_than_or_equal_to_proc
  has_one_attached :greater_than_proc
  has_one_attached :greater_than_or_equal_to_proc
  has_one_attached :between_proc
  has_one_attached :equal_to_proc
  validates :less_than_proc, duration: { less_than: ->(record) { 2.seconds } }
  validates :less_than_or_equal_to_proc, duration: { less_than_or_equal_to: ->(record) { 2.seconds } }
  validates :greater_than_proc, duration: { greater_than: ->(record) { 7.seconds } }
  validates :greater_than_or_equal_to_proc, duration: { greater_than_or_equal_to: ->(record) { 7.seconds } }
  validates :between_proc, duration: { between: -> { 2.seconds..7.seconds } }
  validates :equal_to_proc, duration: { equal_to: ->(record) { 5.seconds } }
end
