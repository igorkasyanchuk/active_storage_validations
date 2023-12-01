# frozen_string_literal: true

# == Schema Information
#
# Table name: size_validator_checks
#
#  id         :integer          not null, primary key
#  created_at :datetime         not null
#  updated_at :datetime         not null
#

class Size::Validator::Check < ApplicationRecord
  has_one_attached :less_than
  has_one_attached :less_than_or_equal_to
  has_one_attached :greater_than
  has_one_attached :greater_than_or_equal_to
  has_one_attached :between
  validates :less_than, size: { less_than: 2.kilobytes }
  validates :less_than_or_equal_to, size: { less_than_or_equal_to: 2.kilobytes }
  validates :greater_than, size: { greater_than: 7.kilobytes }
  validates :greater_than_or_equal_to, size: { greater_than_or_equal_to: 7.kilobytes }
  validates :between, size: { between: 2.kilobytes..7.kilobytes }

  has_one_attached :less_than_proc
  has_one_attached :less_than_or_equal_to_proc
  has_one_attached :greater_than_proc
  has_one_attached :greater_than_or_equal_to_proc
  has_one_attached :between_proc
  validates :less_than_proc, size: { less_than: -> (record) { 2.kilobytes } }
  validates :less_than_or_equal_to_proc, size: { less_than_or_equal_to: -> (record) { 2.kilobytes } }
  validates :greater_than_proc, size: { greater_than: -> (record) { 7.kilobytes } }
  validates :greater_than_or_equal_to_proc, size: { greater_than_or_equal_to: -> (record) { 7.kilobytes } }
  validates :between_proc, size: { between: -> { 2.kilobytes..7.kilobytes } }
end
