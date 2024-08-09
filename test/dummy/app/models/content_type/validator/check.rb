# frozen_string_literal: true

# == Schema Information
#
# Table name: content_type_validator_checks
#
#  id         :integer          not null, primary key
#  created_at :datetime         not null
#  updated_at :datetime         not null
#

class ContentType::Validator::Check < ApplicationRecord
  def self.example_for(type, several: false)
    case type
    when 'symbol'
      several ? [:png, :gif] : :png
    when 'string'
      several ? ['png', 'image/gif'] : 'png'
    when 'regex'
      several ? [/\Aimage\/.*\z/, /\Afile\/.*\z/] : /\Aimage\/.*\z/
    end
  end

  %w(symbol string regex).each do |type|
    has_one_attached :"with_#{type}"
    has_one_attached :"with_#{type}_proc"
    validates :"with_#{type}", content_type: self.example_for(type)
    validates :"with_#{type}_proc", content_type: -> (record) { self.example_for(type) }

    has_one_attached :"in_#{type.pluralize}"
    has_one_attached :"in_#{type.pluralize}_proc"
    validates :"in_#{type.pluralize}", content_type: example_for(type, several: true)
    validates :"in_#{type.pluralize}_proc", content_type: -> (record) { example_for(type, several: true) }
  end
  has_one_attached :content_type_with_parameter
  validates :content_type_with_parameter, content_type: :rar

  has_one_attached :spoofing_protection
  has_one_attached :no_spoofing_protection
  validates :spoofing_protection, content_type: :jpg
  validates :no_spoofing_protection, content_type: { with: :jpg, spoofing_protection: :none}
end
