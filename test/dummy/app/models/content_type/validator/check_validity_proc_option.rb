# frozen_string_literal: true

# == Schema Information
#
# Table name: content_type_validator_check_validity_proc_options
#
#  id         :integer          not null, primary key
#  created_at :datetime         not null
#  updated_at :datetime         not null
#

class ContentType::Validator::CheckValidityProcOption < ApplicationRecord
  has_one_attached :invalid
  validates :invalid, content_type: ->(record) { :invalid }

  has_one_attached :nested_invalid
  validates :nested_invalid, content_type: [ :pdf, ->(record) { :invalid } ]

  has_one_attached :nested_list
  validates :nested_list, content_type: [ :pdf, ->(record) { [ :png, :gif ] } ]
end
