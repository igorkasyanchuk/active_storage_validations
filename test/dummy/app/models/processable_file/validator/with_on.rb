# frozen_string_literal: true

# == Schema Information
#
# Table name: processable_file_validator_with_ons
#
#  id         :integer          not null, primary key
#  created_at :datetime         not null
#  updated_at :datetime         not null
#

class ProcessableFile::Validator::WithOn < ApplicationRecord
  has_one_attached :with_on
  validates :with_on, processable_file: true, on: %i(create update destroy custom)
end
