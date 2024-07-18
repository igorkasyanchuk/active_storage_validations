class ContentTypeSpoofDetector < ApplicationRecord
  has_one_attached :spoofing_protection
  has_one_attached :spoofing_protection_proc
  has_one_attached :no_spoofing_protection
  has_one_attached :no_spoofing_protection_proc
  validates :spoofing_protection, content_type: :jpg
  validates :spoofing_protection_proc, content_type: -> (record) { :jpg }
  validates :no_spoofing_protection, content_type: { with: :jpg, spoofing_protection: :none}
  validates :no_spoofing_protection_proc, content_type: -> (record) { { with: :jpg, spoofing_protection: :none} }

  has_many_attached :many_spoofing_protection
  validates :many_spoofing_protection, content_type: :jpg

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
    { media: 'image', type: :tiff },
    { media: 'image', type: :heic },
    # Video
    { media: 'video', type: :mp4 },
    { media: 'video', type: :avi },
    { media: 'video', type: :wmv },
    { media: 'video', type: :mov },
    { media: 'video', type: :mkv },
    { media: 'video', type: :webm },
    # Audio
    { media: 'audio', type: :mp3 },
    { media: 'audio', type: :wav },
    { media: 'audio', type: :ogg },
    { media: 'audio', type: :aac },
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
  ].each do |content_type|
    has_one_attached :"#{content_type[:media]}_#{content_type[:type]}"
    validates :"#{content_type[:media]}_#{content_type[:type]}", content_type: content_type[:type]
  end
  has_one_attached :application_tar
  validates :application_tar, content_type: ["application/x-tar", "application/x-gtar"]
end
