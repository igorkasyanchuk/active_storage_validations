# frozen_string_literal: true

# == Schema Information
#
# Table name: integration_matchers
#
#  id         :integer          not null, primary key
#  created_at :datetime         not null
#  updated_at :datetime         not null
#

class Integration::Matcher < ApplicationRecord
  has_one_attached :example_1
  validates :example_1, size: { less_than: 10.megabytes, message: "must be less than 10 MB" },
                        content_type: [ "image/png", "image/jpeg", "image/jpeg" ]

  has_one_attached :example_2
  validates :example_2, aspect_ratio: :square,
                        size: { less_than_or_equal_to: 2.megabytes },
                        content_type: { in: [ "image/png", "image/jpeg" ], spoofing_protection: true },
                        processable_file: true
end
