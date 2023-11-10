# frozen_string_literal: true

# == Schema Information
#
# Table name: dimension_matchers
#
#  id         :integer          not null, primary key
#  created_at :datetime         not null
#  updated_at :datetime         not null
#

class Integration::Matcher < ApplicationRecord
  has_one_attached :example_1
  validates :example_1, size: { less_than: 10.megabytes, message: 'must be less than 10 MB' },
                        content_type: ['image/png', 'image/jpg', 'image/jpeg']
end
