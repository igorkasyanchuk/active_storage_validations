# frozen_string_literal: true

require "marcel"

Marcel::MimeType.extend "application/x-rar-compressed", parents: %w[application/x-rar application/vnd.rar]
# libmagic (`file`) names: `application/x-rar` on older releases, `application/vnd.rar` on newer ones (Ubuntu 26.04).
# Neither is a Marcel 1 alias and Marcel 2 only aliases `x-rar`, so the parent links are needed.
Marcel::MimeType.extend "audio/x-hx-aac-adts", parents: %w[audio/aac audio/x-aac]
Marcel::MimeType.extend "video/theora", parents: %w[video/ogg]

# Marcel 2 treats these as aliases (`extend` would warn and rewrite the canonical type).
# Marcel 1 has no TYPE_ALIASES; spoofing relies on these parent links instead.
unless defined?(Marcel::TYPE_ALIASES)
  Marcel::MimeType.extend "audio/x-m4a", parents: %w[audio/mp4]
  Marcel::MimeType.extend "text/xml", parents: %w[application/xml]
end

# Add empty content type
Marcel::MimeType.extend "inode/x-empty", extensions: %w[empty]
