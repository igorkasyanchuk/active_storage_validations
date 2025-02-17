# frozen_string_literal: true

require "marcel"

Marcel::MimeType.extend "application/x-rar-compressed", parents: %(application/x-rar)
Marcel::MimeType.extend "audio/x-hx-aac-adts", parents: %(audio/x-aac)
Marcel::MimeType.extend "audio/x-m4a", parents: %(audio/mp4)
Marcel::MimeType.extend "text/xml", parents: %(application/xml) # alias
Marcel::MimeType.extend "video/theora", parents: %(video/ogg)

# Add empty content type
Marcel::MimeType.extend "inode/x-empty", extensions: %w[empty]
