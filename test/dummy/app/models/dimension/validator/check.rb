# frozen_string_literal: true

# == Schema Information
#
# Table name: dimension_validator_checks
#
#  id         :integer          not null, primary key
#  created_at :datetime         not null
#  updated_at :datetime         not null
#

class Dimension::Validator::Check < ApplicationRecord
  %w[width height].each do |dimension|
    has_one_attached :"#{dimension}"
    has_one_attached :"#{dimension}_min"
    has_one_attached :"#{dimension}_max"
    has_one_attached :"#{dimension}_min_max"
    has_one_attached :"#{dimension}_in"
    validates :"#{dimension}", dimension: { "#{dimension}": 500 }
    validates :"#{dimension}_min", dimension: { "#{dimension}": { min: 500 } }
    validates :"#{dimension}_max", dimension: { "#{dimension}": { max: 500 } }
    validates :"#{dimension}_min_max", dimension: { "#{dimension}": { min: 400, max: 600 } }
    validates :"#{dimension}_in", dimension: { "#{dimension}": { in: 400..600 } }

    has_one_attached :"#{dimension}_proc"
    has_one_attached :"#{dimension}_min_proc"
    has_one_attached :"#{dimension}_max_proc"
    has_one_attached :"#{dimension}_min_max_proc"
    has_one_attached :"#{dimension}_in_proc"
    validates :"#{dimension}_proc", dimension: { "#{dimension}": ->(record) { 500 } }
    validates :"#{dimension}_min_proc", dimension: { "#{dimension}": { min: ->(record) { 500 } } }
    validates :"#{dimension}_max_proc", dimension: { "#{dimension}": { max: ->(record) { 500 } } }
    validates :"#{dimension}_min_max_proc", dimension: { "#{dimension}": { min: ->(record) { 400 }, max: ->(record) { 600 } } }
    validates :"#{dimension}_in_proc", dimension: { "#{dimension}": { in: ->(record) { 400..600 } } }
  end

  %w[min max].each do |bound|
    has_one_attached :"#{bound}"
    validates :"#{bound}", dimension: { "#{bound}": 500..500 }

    has_one_attached :"#{bound}_proc"
    validates :"#{bound}_proc", dimension: { "#{bound}": ->(record) { 500..500 } }
  end

  # Integration tests
  has_one_attached :width_height_exact
  validates :width_height_exact, dimension: { width: 600, height: 600 }
  has_one_attached :width_height_in
  validates :width_height_in, dimension: { width: { in: 550..750 }, height: { in: 550..750 } }

  # Edge cases
  has_one_attached :with_invalid_media_file
  validates :with_invalid_media_file, dimension: { width: 150, height: 150 }
end
