# frozen_string_literal: true

# == Schema Information
#
# Table name: processable_file_validator_using_attachables
#
#  id         :integer          not null, primary key
#  created_at :datetime         not null
#  updated_at :datetime         not null
#

class ProcessableFile::Validator::UsingAttachable < ApplicationRecord
  has_one_attached :using_attachable
  has_many_attached :using_attachables
  validates :using_attachable, processable_file: true
  validates :using_attachables, processable_file: true
end
