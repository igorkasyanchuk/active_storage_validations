# frozen_string_literal: true

# == Schema Information
#
# Table name: pages_validator_checks
#
#  id         :integer          not null, primary key
#  created_at :datetime         not null
#  updated_at :datetime         not null
#

class Pages::Validator::Check < ApplicationRecord
  has_one_attached :less_than
  has_one_attached :less_than_or_equal_to
  has_one_attached :greater_than
  has_one_attached :greater_than_or_equal_to
  has_one_attached :between
  has_one_attached :equal_to
  validates :less_than, pages: { less_than: 2 }
  validates :less_than_or_equal_to, pages: { less_than_or_equal_to: 2 }
  validates :greater_than, pages: { greater_than: 7 }
  validates :greater_than_or_equal_to, pages: { greater_than_or_equal_to: 7 }
  validates :between, pages: { between: 2..7 }
  validates :equal_to, pages: { equal_to: 5 }

  has_one_attached :less_than_proc
  has_one_attached :less_than_or_equal_to_proc
  has_one_attached :greater_than_proc
  has_one_attached :greater_than_or_equal_to_proc
  has_one_attached :between_proc
  has_one_attached :equal_to_proc
  validates :less_than_proc, pages: { less_than: ->(record) { 2 } }
  validates :less_than_or_equal_to_proc, pages: { less_than_or_equal_to: ->(record) { 2 } }
  validates :greater_than_proc, pages: { greater_than: ->(record) { 7 } }
  validates :greater_than_or_equal_to_proc, pages: { greater_than_or_equal_to: ->(record) { 7 } }
  validates :between_proc, pages: { between: -> { 2..7 } }
  validates :equal_to_proc, pages: { equal_to: ->(record) { 5 } }
end
