# frozen_string_literal: true

# == Schema Information
#
# Table name: dimension_validator_using_attachables
#
#  id         :integer          not null, primary key
#  created_at :datetime         not null
#  updated_at :datetime         not null
#

class Dimension::Validator::UsingAttachable < ApplicationRecord
  has_one_attached :using_attachable
  has_many_attached :using_attachables
  validates :using_attachable, dimension: { width: 150, height: 150 }
  validates :using_attachables, dimension: { width: 150, height: 150 }
end
