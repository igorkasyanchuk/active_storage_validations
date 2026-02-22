# frozen_string_literal: true

# == Schema Information
#
# Table name: form_builder_checks
#
#  id         :integer          not null, primary key
#  created_at :datetime         not null
#  updated_at :datetime         not null
#

class FormBuilder::Check < ApplicationRecord
  has_one_attached :with_symbol
  validates :with_symbol, content_type: :png

  has_one_attached :in_array
  validates :in_array, content_type: [ :png, :gif ]

  has_one_attached :with_string_mime
  validates :with_string_mime, content_type: "image/png"

  has_one_attached :with_proc
  validates :with_proc, content_type: ->(record) { :png }

  has_one_attached :with_regex
  validates :with_regex, content_type: /\Aimage\/.*\z/

  has_one_attached :with_non_matching_regex
  validates :with_non_matching_regex, content_type: /\Aimage\/(png|gif)\z/

  has_one_attached :no_content_type_validator
  validates :no_content_type_validator, attached: true

  has_one_attached :no_validator
end
