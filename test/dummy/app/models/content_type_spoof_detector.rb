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

  most_common_mime_types.reject { |common_mime_type| common_mime_type[:type] == :ogv } # issue with ogv
                        .each do |content_type|
    has_one_attached :"#{content_type[:media]}_#{content_type[:type]}"
    validates :"#{content_type[:media]}_#{content_type[:type]}",
              content_type: { with: content_type[:type], spoofing_protection: true }
  end
  has_one_attached :video_ogv
  validates :video_ogv, content_type: { with: 'video/theora', spoofing_protection: true }
end
