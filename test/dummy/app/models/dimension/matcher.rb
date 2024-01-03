# frozen_string_literal: true

# == Schema Information
#
# Table name: dimension_matchers
#
#  title      :string
#  id         :integer          not null, primary key
#  created_at :datetime         not null
#  updated_at :datetime         not null
#

class Dimension::Matcher < ApplicationRecord
  include Validatable

  %i(width height).each do |dimension|
    has_one_attached :"#{dimension}_exact"
    has_one_attached :"#{dimension}_in"
    has_one_attached :"#{dimension}_min"
    has_one_attached :"#{dimension}_max"
    validates :"#{dimension}_exact", dimension: { "#{dimension}": 150 }
    validates :"#{dimension}_in", dimension: { "#{dimension}": { in: 800..1200 } }
    validates :"#{dimension}_min", dimension: { "#{dimension}": { min: 800 } }
    validates :"#{dimension}_max", dimension: { "#{dimension}": { max: 1200 } }

    # Combinations
    has_one_attached :"#{dimension}_exact_with_message"
    has_one_attached :"#{dimension}_in_with_message"
    has_one_attached :"#{dimension}_min_with_message"
    has_one_attached :"#{dimension}_max_with_message"
    validates :"#{dimension}_exact_with_message", dimension: { "#{dimension}": 150, message: 'Invalid dimensions.' }
    validates :"#{dimension}_in_with_message", dimension: { "#{dimension}": { in: 800..1200 }, message: 'Invalid dimensions.' }
    validates :"#{dimension}_min_with_message", dimension: { "#{dimension}": { min: 800 }, message: 'Invalid dimensions.' }
    validates :"#{dimension}_max_with_message", dimension: { "#{dimension}": { max: 1200 }, message: 'Invalid dimensions.' }
  end

  %i(min max).each do |bound|
    has_one_attached :"#{bound}"
    validates :"#{bound}", dimension: { "#{bound}": 800..600 }

    # Combinations
    has_one_attached :"#{bound}_with_message"
    validates :"#{bound}_with_message", dimension: { "#{bound}": 800..600, message: 'Invalid dimensions.' }
  end

  has_one_attached :allow_blank
  validates :allow_blank, dimension: { width: 150, height: 150 }, allow_blank: true

  has_one_attached :with_message
  has_one_attached :without_message
  validates :with_message, dimension: { width: 150, height: 150, message: 'Custom message' }
  validates :without_message, dimension: { width: 150, height: 150 }

  has_one_attached :with_context_symbol
  validates :with_context_symbol, dimension: { width: 150, height: 150 }, on: :update
  has_one_attached :with_context_array
  validates :with_context_array, dimension: { width: 150, height: 150 }, on: %i[update custom]
  has_one_attached :with_several_validators_and_contexts
  validates :with_several_validators_and_contexts, dimension: { width: 150, height: 150 }, on: :update
  validates :with_several_validators_and_contexts, dimension: { width: 150, height: 150 }, on: :custom

  has_one_attached :as_instance
  validates :as_instance, dimension: { width: 150, height: 150 }

  has_one_attached :validatable_different_error_messages
  validates :validatable_different_error_messages, dimension: { width: 150, message: 'Custom message 1' }, if: :title_is_quo_vadis?
  validates :validatable_different_error_messages, dimension: { width: 150, message: 'Custom message 2' }, if: :title_is_american_psycho?

  has_one_attached :failure_message
  validates :failure_message, dimension: { width: 150, height: 150 }
  has_one_attached :failure_message_when_negated
  validates :failure_message_when_negated, dimension: { width: 150, height: 150 }

  # Combinations
  has_one_attached :width_and_height_exact
  has_one_attached :width_and_height_exact_with_message
  validates :width_and_height_exact, dimension: { width: 150, height: 150 }
  validates :width_and_height_exact_with_message, dimension: { width: 150, height: 150, message: 'Invalid dimensions.' }

  has_one_attached :width_and_height_in
  has_one_attached :width_and_height_in_with_message
  validates :width_and_height_in, dimension: { width: { in: 800..1200 }, height: { in: 600..900 } }
  validates :width_and_height_in_with_message, dimension: { width: { in: 800..1200 }, height: { in: 600..900 }, message: 'Invalid dimensions.' }

  has_one_attached :width_and_height_min_max
  has_one_attached :width_and_height_min_max_with_message
  validates :width_and_height_min_max, dimension: { width: { min: 800, max: 1200 }, height: { min: 600, max: 900 } }
  validates :width_and_height_min_max_with_message, dimension: { width: { min: 800, max: 1200 }, height: { min: 600, max: 900 }, message: 'Invalid dimensions.' }
end
