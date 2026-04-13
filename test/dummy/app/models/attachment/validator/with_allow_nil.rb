# frozen_string_literal: true

# == Schema Information
#
# Table name: attachment_validator_with_allow_nils
#
#  id         :integer          not null, primary key
#  created_at :datetime         not null
#  updated_at :datetime         not null
#

class Attachment::Validator::WithAllowNil < ApplicationRecord
  has_one_attached :with_allow_nil
  validate_attached :with_allow_nil, aspect_ratio: :square, size: { less_than: 1.megabyte }, allow_nil: true
end
