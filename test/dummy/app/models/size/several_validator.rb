# frozen_string_literal: true

# == Schema Information
#
# Table name: size_several_validators
#
#  id         :integer          not null, primary key
#  title      :string
#  created_at :datetime         not null
#  updated_at :datetime         not null
#

class Size::SeveralValidator < ApplicationRecord
  has_one_attached :several_size_validators

  validates :title, presence: true

  validates :several_size_validators, size: { less_than: 2.kilobytes, greater_than_or_equal_to: 7.kilobytes }
end
