# frozen_string_literal: true

# == Schema Information
#
# Table name: total_size_validator_check_validity_has_many_attached_onlies
#
#  id         :integer          not null, primary key
#  created_at :datetime         not null
#  updated_at :datetime         not null
#

class TotalSize::Validator::CheckValidityHasManyAttachedOnly < ApplicationRecord
  has_one_attached :invalid
  validates :invalid, total_size: { less_than: 2.kilobytes }
end
