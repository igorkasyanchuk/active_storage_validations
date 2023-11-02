# frozen_string_literal: true

# == Schema Information
#
# Table name: portfolios
#
#  id         :integer          not null, primary key
#  title      :string
#  created_at :datetime         not null
#  updated_at :datetime         not null
#

class Size::Portfolio < ApplicationRecord
  has_one_attached :size_less_than
  has_one_attached :size_less_than_or_equal_to
  has_one_attached :size_greater_than
  has_one_attached :size_greater_than_or_equal_to
  has_one_attached :size_between
  has_one_attached :size_with_message

  has_one_attached :proc_size_less_than
  has_one_attached :proc_size_less_than_or_equal_to
  has_one_attached :proc_size_greater_than
  has_one_attached :proc_size_greater_than_or_equal_to
  has_one_attached :proc_size_between
  has_one_attached :proc_size_with_message

  has_many_attached :many_size_between

  validates :title, presence: true

  validates :size_less_than, size: { less_than: 2.kilobytes }
  validates :size_less_than_or_equal_to, size: { less_than_or_equal_to: 2.kilobytes }
  validates :size_greater_than, size: { greater_than: 7.kilobytes }
  validates :size_greater_than_or_equal_to, size: { greater_than_or_equal_to: 7.kilobytes }
  validates :size_between, size: { between: 2.kilobytes..7.kilobytes }
  validates :size_with_message, size: { between: 2.kilobytes..7.kilobytes, message: 'is not in required file size range' }

  validates :many_size_between, size: { between: 2.kilobytes..7.kilobytes }

  validates :proc_size_less_than, size: { less_than: -> (record) { 2.kilobytes } }
  validates :proc_size_less_than_or_equal_to, size: { less_than_or_equal_to: -> (record) { 2.kilobytes } }
  validates :proc_size_greater_than, size: { greater_than: -> (record) { 7.kilobytes } }
  validates :proc_size_greater_than_or_equal_to, size: { greater_than_or_equal_to: -> (record) { 7.kilobytes } }
  validates :proc_size_between, size: { between: -> (record) { 2.kilobytes..7.kilobytes } }
  validates :proc_size_with_message, size: { between: -> (record) { 2.kilobytes..7.kilobytes } }
end
