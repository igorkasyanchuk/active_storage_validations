# frozen_string_literal: true

# == Schema Information
#
# Table name: content_type_validator_with_ifs
#
#  title      :string
#  id         :integer          not null, primary key
#  created_at :datetime         not null
#  updated_at :datetime         not null
#

class ContentType::Validator::WithIf < ApplicationRecord
  has_one_attached :with_if
  validates :with_if, content_type: :webp, if: -> { self.title == 'Right title' }
end
