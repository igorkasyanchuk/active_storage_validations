# frozen_string_literal: true

# == Schema Information
#
# Table name: content_type_validator_using_attachables
#
#  id         :integer          not null, primary key
#  created_at :datetime         not null
#  updated_at :datetime         not null
#

class ContentType::Validator::UsingAttachable < ApplicationRecord
  has_one_attached :using_attachable
  has_many_attached :using_attachables
  validates :using_attachable, content_type: :png
  validates :using_attachables, content_type: :png
end
