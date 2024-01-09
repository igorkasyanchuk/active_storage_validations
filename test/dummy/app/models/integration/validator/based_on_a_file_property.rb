# frozen_string_literal: true

# == Schema Information
#
# Table name: integration_validator_based_on_a_file_properties
#
#  id         :integer          not null, primary key
#  created_at :datetime         not null
#  updated_at :datetime         not null
#

class Integration::Validator::BasedOnAFileProperty < ApplicationRecord
  has_one_attached :picture
  validates :picture,
            content_type: ['image/png', 'image/jpg', 'image/gif'],
            size: { less_than: -> (record) { record.picture.blob.content_type == "image/png" ? 15.kilobytes : 5.kilobytes} }
end
