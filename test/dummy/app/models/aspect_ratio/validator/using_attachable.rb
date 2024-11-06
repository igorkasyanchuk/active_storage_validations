# frozen_string_literal: true

# == Schema Information
#
# Table name: aspect_ratio_validator_using_attachables
#
#  id         :integer          not null, primary key
#  created_at :datetime         not null
#  updated_at :datetime         not null
#

class AspectRatio::Validator::UsingAttachable < ApplicationRecord
  has_one_attached :using_attachable
  has_many_attached :using_attachables
  validates :using_attachable, aspect_ratio: :square
  validates :using_attachables, aspect_ratio: :square
end
