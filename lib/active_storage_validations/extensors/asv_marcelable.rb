# frozen_string_literal: true

require "marcel"

Marcel::MimeType.extend "application/x-rar-compressed", parents: %w[application/x-rar]
Marcel::MimeType.extend "audio/x-hx-aac-adts", parents: %w[audio/x-aac]
Marcel::MimeType.extend "audio/x-m4a", parents: %w[audio/mp4]
Marcel::MimeType.extend "text/xml", parents: %w[application/xml] # alias
Marcel::MimeType.extend "video/theora", parents: %w[video/ogg]

# Add empty content type
Marcel::MimeType.extend "inode/x-empty", extensions: %w[empty]
