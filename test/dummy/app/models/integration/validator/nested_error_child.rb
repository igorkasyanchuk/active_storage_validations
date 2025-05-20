# frozen_string_literal: true

# == Schema Information
#
# Table name: integration_validator_nested_error_children
#
#  id         :integer          not null, primary key
#  created_at :datetime         not null
#  updated_at :datetime         not null
#

class Integration::Validator::NestedErrorChild < ApplicationRecord
  belongs_to :parent,
             class_name: "Integration::Validator::NestedErrorParent"

  has_one_attached :image
  validates :image, content_type: :png
end
