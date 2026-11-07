# frozen_string_literal: true

# == Schema Information
#
# Table name: integration_validator_nested_error_parents
#
#  id         :integer          not null, primary key
#  created_at :datetime         not null
#  updated_at :datetime         not null
#

class Integration::Validator::NestedErrorParent < ApplicationRecord
  has_one :child,
          class_name: "Integration::Validator::NestedErrorChild",
          foreign_key: :nested_error_parent_id,
          inverse_of: :parent
  accepts_nested_attributes_for :child, update_only: true
end
