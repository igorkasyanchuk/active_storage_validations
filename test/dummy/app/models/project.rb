# frozen_string_literal: true

# == Schema Information
#
# Table name: projects
#
#  id         :integer          not null, primary key
#  title      :string
#  created_at :datetime         not null
#  updated_at :datetime         not null
#

class Project < ApplicationRecord

  has_one_attached :dimension_exact
  has_one_attached :dimension_exact_with_message
  has_one_attached :dimension_range
  has_one_attached :dimension_min
  has_one_attached :dimension_max
  has_many_attached :documents
  has_many_attached :dimension_images

  has_one_attached :proc_dimension_exact
  has_one_attached :proc_dimension_exact_with_message
  has_one_attached :proc_dimension_range
  has_one_attached :proc_dimension_min
  has_one_attached :proc_dimension_max
  has_many_attached :proc_documents
  has_many_attached :proc_dimension_images

  validates :title, presence: true

  validates :documents, limit: { min: 1, max: 3 }

  validates :dimension_exact,               dimension: { width: 150, height: 150 }
  validates :dimension_range,               dimension: { width: { in: 800..1200 }, height: { in: 600..900 } }
  validates :dimension_min,                 dimension: { min: 800..600 }
  validates :dimension_max,                 dimension: { max: 1200..900 }
  validates :dimension_images,              dimension: { width: { min: 800, max: 1200 }, height: { min: 600, max: 900 } }

  validates :proc_documents, limit: { min: -> (record) {1}, max: -> (record) {3} }

  validates :proc_dimension_exact,               dimension: { width: -> (record) {150}, height: -> (record) {150} }
  validates :proc_dimension_range,               dimension: { width: { in: -> (record) {800..1200} }, height: { in: -> (record) {600..900} } }
  validates :proc_dimension_min,                 dimension: { min: -> (record) {800..600} }
  validates :proc_dimension_max,                 dimension: { max: -> (record) {1200..900} }
  # validates :proc_dimension_images,              dimension: { width: { min: -> (record) {800}, max: -> (record) {1200} }, height: { min: -> (record) {600}, max: -> (record) {900} } }
end
