# frozen_string_literal: true

# == Schema Information
#
# Table name: aspect_ratio_validator_checks
#
#  id         :integer          not null, primary key
#  created_at :datetime         not null
#  updated_at :datetime         not null
#

class AspectRatio::Validator::Check < ApplicationRecord
  %i(square portrait landscape).each do |named_aspect_ratio|
    has_one_attached :"with_#{named_aspect_ratio}"
    has_one_attached :"with_#{named_aspect_ratio}_proc"
    validates :"with_#{named_aspect_ratio}", aspect_ratio: named_aspect_ratio
    validates :"with_#{named_aspect_ratio}_proc", aspect_ratio: -> (record) { named_aspect_ratio }
  end
  has_one_attached :with_regex
  has_one_attached :with_regex_proc
  validates :with_regex, aspect_ratio: :is_16_9
  validates :with_regex_proc, aspect_ratio: :is_16_9

  has_one_attached :with_invalid_image_file
  validates :with_invalid_image_file, aspect_ratio: :square

  has_one_attached :in_aspect_ratios
  has_one_attached :in_aspect_ratios_proc
  validates :in_aspect_ratios, aspect_ratio: %i(square portrait is_16_9)
  validates :in_aspect_ratios_proc, aspect_ratio: -> (record) { %i(square portrait is_16_9) }
end
