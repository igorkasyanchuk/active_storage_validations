# frozen_string_literal: true

# == Schema Information
#
# Table name: size_validator_with_stricts
#
#  id         :integer          not null, primary key
#  created_at :datetime         not null
#  updated_at :datetime         not null
#

class Size::Validator::WithStrict < ApplicationRecord
  class StrictException < StandardError; end

  has_one_attached :with_strict
  validates :with_strict, size: { less_than: 2.kilobytes }, strict: StrictException
end
