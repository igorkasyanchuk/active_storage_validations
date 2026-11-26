# frozen_string_literal: true

# == Schema Information
#
# Table name: integration_validator_without_new_file_allow_blanks
#
#  id         :integer          not null, primary key
#  created_at :datetime         not null
#  updated_at :datetime         not null
#

# With :allow_blank, Active Model's own blank check (one query) is kept.
class Integration::Validator::WithoutNewFileAllowBlank < ApplicationRecord
  has_many_attached :images
  validates :images, dimension: { width: { max: 1000 } }, allow_blank: true
end
