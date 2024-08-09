# frozen_string_literal: true

# == Schema Information
#
# Table name: total_size_validator_with_allow_blanks
#
#  id         :integer          not null, primary key
#  created_at :datetime         not null
#  updated_at :datetime         not null
#

class TotalSize::Validator::WithAllowBlank < ApplicationRecord
  has_many_attached :with_allow_blank
  validates :with_allow_blank, total_size: { less_than: 2.kilobytes }, allow_blank: true
end
