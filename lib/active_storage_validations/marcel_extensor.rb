if Rails.gem_version >= Gem::Version.new('6.1.4')
  # Marcel parent feature is only available starting from marcel v1.0.3
  # Rails >= 6.1.4 relies on marcel ~> 1.0
  # Rails < 6.1.4 relies on marcel ~> 0.3.1
  Marcel::MimeType.extend "application/x-rar-compressed", parents: %(application/x-rar)
  Marcel::MimeType.extend "audio/x-hx-aac-adts", parents: %(audio/x-aac)
  Marcel::MimeType.extend "text/xml", parents: %(application/xml) # alias
end
