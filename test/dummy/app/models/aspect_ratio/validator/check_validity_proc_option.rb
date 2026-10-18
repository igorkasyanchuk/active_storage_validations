# frozen_string_literal: true

# == Schema Information
#
# Table name: aspect_ratio_validator_check_validity_proc_options
#
#  id         :integer          not null, primary key
#  created_at :datetime         not null
#  updated_at :datetime         not null
#

class AspectRatio::Validator::CheckValidityProcOption < ApplicationRecord
  has_one_attached :invalid
  validates :invalid, aspect_ratio: ->(record) { :invalid }

  has_one_attached :nested_invalid
  validates :nested_invalid, aspect_ratio: { in: [ :square, ->(record) { "16:9" } ] }

  has_one_attached :nested_list
  validates :nested_list, aspect_ratio: { in: [ :portrait, ->(record) { [ :square, :landscape ] } ] }
end
