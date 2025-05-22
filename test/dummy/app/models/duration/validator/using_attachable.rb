# frozen_string_literal: true

# == Schema Information
#
# Table name: duration_validator_using_attachables
#
#  id         :integer          not null, primary key
#  created_at :datetime         not null
#  updated_at :datetime         not null
#

class Duration::Validator::UsingAttachable < ApplicationRecord
  has_one_attached :using_attachable
  has_many_attached :using_attachables
  validates :using_attachable, duration: { less_than_or_equal_to: 5.seconds }
  validates :using_attachables, duration: { less_than_or_equal_to: 5.seconds }
end
