# frozen_string_literal: true

# == Schema Information
#
# Table name: size_several_validator_procs
#
#  id         :integer          not null, primary key
#  title      :string
#  created_at :datetime         not null
#  updated_at :datetime         not null
#

class Size::SeveralValidatorProc < ApplicationRecord
  has_one_attached :proc_several_size_validators

  validates :title, presence: true

  validates :proc_several_size_validators, size: { less_than: -> (record) { 2.kilobytes }, greater_than_or_equal_to: -> (record) { 7.kilobytes } }
end
