# frozen_string_literal: true

# == Schema Information
#
# Table name: content_type_validators
#
#  id         :integer          not null, primary key
#  created_at :datetime         not null
#  updated_at :datetime         not null
#

class ContentType::Validator < ApplicationRecord
  has_one_attached :with_context
  validates :with_context, content_type: :webp, on: %i(create update destroy custom)
end
