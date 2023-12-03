# frozen_string_literal: true

# == Schema Information
#
# Table name: content_type_validator_with_on
#
#  id         :integer          not null, primary key
#  created_at :datetime         not null
#  updated_at :datetime         not null
#

class ContentType::Validator::WithOn < ApplicationRecord
  has_one_attached :with_on
  validates :with_on, content_type: :webp, on: %i(create update destroy custom)
end
