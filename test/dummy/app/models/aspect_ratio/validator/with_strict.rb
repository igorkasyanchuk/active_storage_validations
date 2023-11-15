# frozen_string_literal: true

# == Schema Information
#
# Table name: aspect_ratio_validator_with_stricts
#
#  id         :integer          not null, primary key
#  created_at :datetime         not null
#  updated_at :datetime         not null
#

class AspectRatio::Validator::WithStrict < ApplicationRecord
  class StrictException < StandardError; end

  has_one_attached :with_strict
  validates :with_strict, aspect_ratio: :square, strict: StrictException
end
