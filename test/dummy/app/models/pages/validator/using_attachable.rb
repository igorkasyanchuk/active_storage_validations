# frozen_string_literal: true

# == Schema Information
#
# Table name: pages_validator_using_attachables
#
#  id         :integer          not null, primary key
#  created_at :datetime         not null
#  updated_at :datetime         not null
#

class Pages::Validator::UsingAttachable < ApplicationRecord
  has_one_attached :using_attachable
  has_many_attached :using_attachables
  validates :using_attachable, pages: { less_than_or_equal_to: 5 }
  validates :using_attachables, pages: { less_than_or_equal_to: 5 }
end
