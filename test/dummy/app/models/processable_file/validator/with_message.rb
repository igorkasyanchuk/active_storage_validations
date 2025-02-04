# frozen_string_literal: true

# == Schema Information
#
# Table name: processable_file_validator_with_messages
#
#  id         :integer          not null, primary key
#  created_at :datetime         not null
#  updated_at :datetime         not null
#

class ProcessableFile::Validator::WithMessage < ApplicationRecord
  has_one_attached :with_message
  validates :with_message, processable_file: { message: "Custom message" }
end
