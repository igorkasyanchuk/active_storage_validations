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

  # Most common mime types
  [
    # Image
    { media: 'image', type: :jpg },
    { media: 'image', type: :jpeg },
    { media: 'image', type: :png },
    { media: 'image', type: :gif },
    { media: 'image', type: :webp },
    { media: 'image', type: :svg },
    { media: 'image', type: :bmp },
    { media: 'image', type: :psd },
    { media: 'image', type: :tiff },
    { media: 'image', type: :heic },
    # Video
    { media: 'video', type: :mp4 },
    { media: 'video', type: :avi },
    { media: 'video', type: :wmv },
    { media: 'video', type: :mov },
    { media: 'video', type: :mkv },
    # { media: 'video', type: :ogv }, => issue with content_type validator, handled below
    { media: 'video', type: :webm },
    # Audio
    { media: 'audio', type: :mp3 },
    { media: 'audio', type: :m4a },
    { media: 'audio', type: :wav },
    { media: 'audio', type: :ogg },
    { media: 'audio', type: :aac },
    { media: 'audio', type: :flac },
    # Text
    { media: 'text', type: :txt },
    { media: 'text', type: :csv },
    { media: 'text', type: :html },
    { media: 'text', type: :css },
    ## Application
    { media: 'application', type: :json },
    { media: 'application', type: :xml },
    { media: 'application', type: :pdf },
    { media: 'application', type: :doc },
    { media: 'application', type: :docx },
    { media: 'application', type: :xls },
    { media: 'application', type: :xlsx },
    { media: 'application', type: :ppt },
    { media: 'application', type: :pptx },
    { media: 'application', type: :ppsx },
    { media: 'application', type: :odt },
    { media: 'application', type: :ods },
    { media: 'application', type: :odp },
    { media: 'application', type: :pages },
    { media: 'application', type: :numbers },
    { media: 'application', type: :key },
    { media: 'application', type: :zip },
    { media: 'application', type: :'7z' },
    { media: 'application', type: :rar },
    { media: 'application', type: :gz },
    # { media: 'application', type: :tar }, => issue with content_type validator, handled below
  ].each do |content_type|
    has_one_attached :"#{content_type[:media]}_#{content_type[:type]}"
    validates :"#{content_type[:media]}_#{content_type[:type]}",
              content_type: { with: content_type[:type], spoofing_protection: true }
  end

  has_one_attached :video_ogv
  validates :video_ogv, content_type: { with: 'video/theora', spoofing_protection: true }
  has_one_attached :application_tar
  validates :application_tar, content_type: { in: ['application/x-tar', 'application/x-gtar'], spoofing_protection: true }
end
