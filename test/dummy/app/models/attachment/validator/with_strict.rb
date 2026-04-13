# frozen_string_literal: true

# == Schema Information
#
# Table name: attachment_validator_with_stricts
#
#  id         :integer          not null, primary key
#  created_at :datetime         not null
#  updated_at :datetime         not null
#

class Attachment::Validator::WithStrict < ApplicationRecord
  class StrictException < StandardError; end

  has_one_attached :with_strict
  validate_attached :with_strict, aspect_ratio: :square, size: { less_than: 1.megabyte }, strict: StrictException
end
