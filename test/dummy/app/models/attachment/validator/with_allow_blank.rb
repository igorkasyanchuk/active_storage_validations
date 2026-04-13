# frozen_string_literal: true

# == Schema Information
#
# Table name: attachment_validator_with_allow_blanks
#
#  id         :integer          not null, primary key
#  created_at :datetime         not null
#  updated_at :datetime         not null
#

class Attachment::Validator::WithAllowBlank < ApplicationRecord
  has_one_attached :with_allow_blank
  validate_attached :with_allow_blank, aspect_ratio: :square, size: { less_than: 1.megabyte }, allow_blank: true
end
