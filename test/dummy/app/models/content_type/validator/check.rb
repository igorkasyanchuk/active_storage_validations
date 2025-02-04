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
    when "symbol"
      several ? [ :png, :gif ] : :png
    when "string"
      several ? [ "png", "image/gif" ] : "png"
    when "regex"
      several ? [ /\Aimage\/.*\z/, /\Afile\/.*\z/ ] : /\Aimage\/.*\z/
    end
  end

  has_one_attached :extension_content_type_mismatch
  validates :extension_content_type_mismatch, content_type: :png
  has_one_attached :extension_two_extensions_docx
  validates :extension_two_extensions_docx, content_type: "application/vnd.openxmlformats-officedocument.wordprocessingml.document"
  has_one_attached :extension_two_extensions_pdf
  validates :extension_two_extensions_pdf, content_type: "application/pdf"
  has_one_attached :extension_upcase_extension
  validates :extension_upcase_extension, content_type: "application/pdf"
  has_one_attached :extension_missing_extension
  validates :extension_missing_extension, content_type: "application/pdf"

  %w[symbol string regex].each do |type|
    has_one_attached :"with_#{type}"
    has_one_attached :"with_#{type}_proc"
    validates :"with_#{type}", content_type: self.example_for(type)
    validates :"with_#{type}_proc", content_type: ->(record) { self.example_for(type) }

    has_one_attached :"in_#{type.pluralize}"
    has_one_attached :"in_#{type.pluralize}_proc"
    validates :"in_#{type.pluralize}", content_type: example_for(type, several: true)
    validates :"in_#{type.pluralize}_proc", content_type: ->(record) { example_for(type, several: true) }
  end

  most_common_mime_types.reject { |common_mime_type| common_mime_type[:type] == :ogv } # issue with ogv
                        .each do |content_type|
    has_one_attached :"#{content_type[:media]}_#{content_type[:type]}"
    validates :"#{content_type[:media]}_#{content_type[:type]}",
              content_type: content_type[:type]
    has_one_attached :"#{content_type[:media]}_#{content_type[:type]}_spoof"
    validates :"#{content_type[:media]}_#{content_type[:type]}_spoof",
              content_type: { with: content_type[:type], spoofing_protection: true }
  end
  has_one_attached :video_ogv
  validates :video_ogv, content_type: [ "video/theora" ]
  has_one_attached :video_ogv_spoof
  validates :video_ogv_spoof, content_type: { with: "video/theora", spoofing_protection: true }

  has_one_attached :content_type_with_parameter
  validates :content_type_with_parameter, content_type: :rar

  has_one_attached :spoofing_protection
  has_one_attached :no_spoofing_protection
  validates :spoofing_protection, content_type: { with: :jpg, spoofing_protection: true }
  validates :no_spoofing_protection, content_type: :jpg
  has_many_attached :many_spoofing_protection
  validates :many_spoofing_protection, content_type: { with: :jpg, spoofing_protection: true }
end
