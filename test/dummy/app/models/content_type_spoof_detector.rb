class ContentTypeSpoofDetector < ApplicationRecord
  has_one_attached :spoofing_protection
  has_one_attached :spoofing_protection_proc
  has_one_attached :no_spoofing_protection
  has_one_attached :no_spoofing_protection_proc
  validates :spoofing_protection, content_type: { with: :jpg, spoofing_protection: true }
  validates :spoofing_protection_proc, content_type: { with: ->(record) { :jpg }, spoofing_protection: true }
  validates :no_spoofing_protection, content_type: :jpg
  validates :no_spoofing_protection_proc, content_type: { with: ->(record) { :jpg } }

  has_many_attached :many_spoofing_protection
  validates :many_spoofing_protection, content_type: { with: :jpg, spoofing_protection: true }

  most_common_mime_types.each do |content_type|
    has_one_attached :"#{content_type[:media]}_#{content_type[:type]}"
    validates :"#{content_type[:media]}_#{content_type[:type]}",
              content_type: { with: content_type[:type], spoofing_protection: true }
  end
end
