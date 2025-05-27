# frozen_string_literal: true

# == Schema Information
#
# Table name: total_size_validator_checks
#
#  id         :integer          not null, primary key
#  created_at :datetime         not null
#  updated_at :datetime         not null
#

class TotalSize::Validator::Check < ApplicationRecord
  has_many_attached :less_than
  has_many_attached :less_than_or_equal_to
  has_many_attached :greater_than
  has_many_attached :greater_than_or_equal_to
  has_many_attached :between
  has_many_attached :equal_to
  validates :less_than, total_size: { less_than: 2.kilobytes }
  validates :less_than_or_equal_to, total_size: { less_than_or_equal_to: 2.kilobytes }
  validates :greater_than, total_size: { greater_than: 7.kilobytes }
  validates :greater_than_or_equal_to, total_size: { greater_than_or_equal_to: 7.kilobytes }
  validates :between, total_size: { between: 2.kilobytes..7.kilobytes }
  validates :equal_to, total_size: { equal_to: 5.kilobytes }

  has_many_attached :less_than_proc
  has_many_attached :less_than_or_equal_to_proc
  has_many_attached :greater_than_proc
  has_many_attached :greater_than_or_equal_to_proc
  has_many_attached :between_proc
  has_many_attached :equal_to_proc
  validates :less_than_proc, total_size: { less_than: ->(record) { 2.kilobytes } }
  validates :less_than_or_equal_to_proc, total_size: { less_than_or_equal_to: ->(record) { 2.kilobytes } }
  validates :greater_than_proc, total_size: { greater_than: ->(record) { 7.kilobytes } }
  validates :greater_than_or_equal_to_proc, total_size: { greater_than_or_equal_to: ->(record) { 7.kilobytes } }
  validates :between_proc, total_size: { between: -> { 2.kilobytes..7.kilobytes } }
  validates :equal_to_proc, total_size: { equal_to: ->(record) { 5.kilobytes } }
end
