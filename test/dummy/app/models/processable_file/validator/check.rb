# frozen_string_literal: true

# == Schema Information
#
# Table name: processable_file_validator_checks
#
#  id         :integer          not null, primary key
#  created_at :datetime         not null
#  updated_at :datetime         not null
#

class ProcessableFile::Validator::Check < ApplicationRecord
  has_one_attached :has_to_be_processable
  validates :has_to_be_processable, processable_file: true
end
