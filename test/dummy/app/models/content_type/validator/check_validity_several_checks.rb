# frozen_string_literal: true

# == Schema Information
#
# Table name: content_type_validator_check_validity_several_checks
#
#  id         :integer          not null, primary key
#  created_at :datetime         not null
#  updated_at :datetime         not null
#

class ContentType::Validator::CheckValiditySeveralChecks < ApplicationRecord
  has_one_attached :invalid
  validates :invalid, content_type: { with: :png, in: %w[image/png image/jpeg] }
end
