# frozen_string_literal: true

# Lists partially based on
# https://developer.mozilla.org/en-US/docs/Web/HTTP/Basics_of_HTTP/MIME_types/Common_types

module FixtureFiles
  MOST_COMMON_MIME_TYPES = [
    # Image
    { mime_type: "image/jpeg", extension: "jpg" },
    { mime_type: "image/jpeg", extension: "jpeg" },
    { mime_type: "image/png", extension: "png" },
    { mime_type: "image/gif", extension: "gif" },
    { mime_type: "image/webp", extension: "webp" },
    { mime_type: "image/svg+xml", extension: "svg" },
    { mime_type: "image/bmp", extension: "bmp" },
    { mime_type: "image/vnd.adobe.photoshop", extension: "psd" },
    { mime_type: "image/tiff", extension: "tiff" },
    { mime_type: "image/heic", extension: "heic" },

    # Video
    { mime_type: "video/mp4", extension: "mp4" },
    { mime_type: "video/x-msvideo", extension: "avi" },
    { mime_type: "video/x-ms-wmv", extension: "wmv" },
    { mime_type: "video/quicktime", extension: "mov" },
    { mime_type: "video/x-matroska", extension: "mkv" },
    { mime_type: "video/ogg", extension: "ogv" },
    { mime_type: "video/webm", extension: "webm" },

    # Audio
    { mime_type: "audio/mpeg", extension: "mp3" },
    { mime_type: "audio/mp4", extension: "m4a" },
    { mime_type: "audio/x-wav", extension: "wav" },
    { mime_type: "audio/ogg", extension: "ogg" },
    { mime_type: "audio/aac", extension: "aac" },
    { mime_type: "audio/flac", extension: "flac" },

    # Text
    { mime_type: "text/plain", extension: "txt" },
    { mime_type: "text/csv", extension: "csv" },
    { mime_type: "text/html", extension: "html" },
    { mime_type: "text/css", extension: "css" },

    # Application
    { mime_type: "application/json", extension: "json" },
    { mime_type: "application/xml", extension: "xml" },
    { mime_type: "application/pdf", extension: "pdf" },
    ## Microsoft Office documents
    { mime_type: "application/msword", extension: "doc" },
    { mime_type: "application/vnd.openxmlformats-officedocument.wordprocessingml.document", extension: "docx" },
    { mime_type: "application/vnd.ms-excel", extension: "xls" },
    { mime_type: "application/vnd.openxmlformats-officedocument.spreadsheetml.sheet", extension: "xlsx" },
    { mime_type: "application/vnd.ms-powerpoint", extension: "ppt" },
    { mime_type: "application/vnd.openxmlformats-officedocument.presentationml.presentation", extension: "pptx" },
    { mime_type: "application/vnd.openxmlformats-officedocument.presentationml.slideshow", extension: "ppsx" },
    ## Open Office documents
    { mime_type: "application/vnd.oasis.opendocument.text", extension: "odt" },
    { mime_type: "application/vnd.oasis.opendocument.spreadsheet", extension: "ods" },
    { mime_type: "application/vnd.oasis.opendocument.presentation", extension: "odp" },
    ## Apple documents
    { mime_type: "application/vnd.apple.pages", extension: "pages" },
    { mime_type: "application/vnd.apple.numbers", extension: "numbers" },
    { mime_type: "application/vnd.apple.keynote", extension: "key" },
    ## Archives
    { mime_type: "application/zip", extension: "zip" },
    { mime_type: "application/x-7z-compressed", extension: "7z" },
    { mime_type: "application/x-rar-compressed", extension: "rar" },
    { mime_type: "application/gzip", extension: "gz" },
    { mime_type: "application/x-tar", extension: "tar" }
  ].freeze

  def most_common_mime_types
    MOST_COMMON_MIME_TYPES
  end

  # Defines jpg_file, jpeg_file, png_file, … (see most_common_mime_types)
  MOST_COMMON_MIME_TYPES.each do |mime_type|
    define_method(:"#{mime_type[:extension]}_file") do
      fixture_file(
        File.join("most_common_mime_types", "example.#{mime_type[:extension]}"),
        filename: "example.#{mime_type[:extension]}",
        content_type: mime_type[:mime_type]
      )
    end
  end
end
