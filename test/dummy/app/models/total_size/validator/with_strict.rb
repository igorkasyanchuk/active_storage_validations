# frozen_string_literal: true

# == Schema Information
#
# Table name: total_size_validator_with_stricts
#
#  id         :integer          not null, primary key
#  created_at :datetime         not null
#  updated_at :datetime         not null
#

class TotalSize::Validator::WithStrict < ApplicationRecord
  class StrictException < StandardError; end

  has_many_attached :with_strict
  validates :with_strict, total_size: { less_than: 2.kilobytes }, strict: StrictException
end
