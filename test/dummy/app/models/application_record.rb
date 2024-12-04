class ApplicationRecord < ActiveRecord::Base
  self.abstract_class = true

  # Class method that references the most common mime types.
  # After adding a new one, make sure to have the corresponding example file in
  # test/dummy/public/most_common_mime_types
  def self.most_common_mime_types
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
      { media: 'video', type: :ogv },
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
      { media: 'application', type: :tar }
    ]
  end
end
