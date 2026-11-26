# frozen_string_literal: true

# Declared / detected content type pairs for content_type spoofing_protection.
#
# Detected types are what `file` (5.41) and Magika (cli 1.0.2; CI runs
# cli/v1.1.0) report for the test/dummy/public fixtures; declared types are
# what Rails stores once it has identified the upload, or what a direct upload
# / identify: false keeps.
module FixtureFiles
  # Genuine uploads: [declared, detected]. Each pair was observed on a real
  # fixture with at least one backend.
  SPOOFING_GENUINE_PAIRS = [
    # Same type
    %w[image/jpeg image/jpeg],
    %w[image/png image/png],
    %w[image/gif image/gif],
    %w[image/webp image/webp],
    %w[image/svg+xml image/svg+xml],
    %w[image/bmp image/bmp],
    %w[image/tiff image/tiff],
    %w[image/heic image/heic],
    %w[image/vnd.adobe.photoshop image/vnd.adobe.photoshop],
    %w[video/mp4 video/mp4],
    %w[video/quicktime video/quicktime],
    %w[video/x-matroska video/x-matroska],
    %w[video/x-msvideo video/x-msvideo],
    %w[video/webm video/webm],
    %w[video/ogg video/ogg],
    %w[audio/mpeg audio/mpeg],
    %w[audio/ogg audio/ogg],
    %w[audio/flac audio/flac],
    %w[audio/x-wav audio/x-wav],
    %w[audio/x-m4a audio/x-m4a],
    %w[text/plain text/plain],
    %w[text/csv text/csv],
    %w[text/css text/css],
    %w[text/html text/html],
    %w[application/json application/json],
    %w[application/pdf application/pdf],
    %w[application/msword application/msword],
    %w[application/vnd.ms-excel application/vnd.ms-excel],
    %w[application/vnd.ms-powerpoint application/vnd.ms-powerpoint],
    %w[application/vnd.openxmlformats-officedocument.wordprocessingml.document application/vnd.openxmlformats-officedocument.wordprocessingml.document],
    %w[application/vnd.openxmlformats-officedocument.spreadsheetml.sheet application/vnd.openxmlformats-officedocument.spreadsheetml.sheet],
    %w[application/vnd.openxmlformats-officedocument.presentationml.presentation application/vnd.openxmlformats-officedocument.presentationml.presentation],
    %w[application/vnd.oasis.opendocument.text application/vnd.oasis.opendocument.text],
    %w[application/vnd.oasis.opendocument.spreadsheet application/vnd.oasis.opendocument.spreadsheet],
    %w[application/vnd.oasis.opendocument.presentation application/vnd.oasis.opendocument.presentation],
    %w[application/zip application/zip],
    %w[application/gzip application/gzip],
    %w[application/x-tar application/x-tar],
    %w[application/x-7z-compressed application/x-7z-compressed],
    # Marcel aliases / gem parent links (libmagic names)
    %w[application/xml text/xml],
    %w[text/xml text/xml],
    %w[audio/mp4 audio/x-m4a],
    %w[audio/aac audio/x-hx-aac-adts],
    %w[application/x-rar-compressed application/x-rar],
    %w[application/x-rar-compressed application/vnd.rar],
    # Detected type is an ancestor of the declared one (sniffer less specific)
    %w[text/csv text/plain],
    %w[text/css text/plain],
    %w[application/vnd.apple.pages application/zip],
    %w[application/vnd.apple.numbers application/zip],
    %w[application/vnd.apple.keynote application/zip],
    %w[application/vnd.openxmlformats-officedocument.presentationml.slideshow application/vnd.openxmlformats-officedocument.presentationml.presentation],
    %w[application/vnd.openxmlformats-officedocument.wordprocessingml.document application/zip],
    %w[application/vnd.ms-excel.sheet.macroenabled.12 application/zip],
    %w[video/x-ms-wmv video/x-ms-asf],
    %w[audio/mp4 video/mp4],
    %w[audio/x-m4a video/mp4],
    # Same container, audio / video flavor (SAME_CONTAINER_CONTENT_TYPES)
    %w[video/ogg audio/ogg],
    %w[video/theora audio/ogg],
    %w[audio/webm video/webm]
  ].freeze

  # Accepted on purpose: the detected type is a more specific kind of the
  # declared one, so the file really is what it claims (a PHP script is plain
  # text, a JAR is a ZIP). Listed so that changing this is a visible decision.
  SPOOFING_DESCENDANT_PAIRS = [
    %w[text/plain text/csv],
    %w[text/plain text/x-php],
    %w[text/plain text/x-python],
    %w[text/plain image/svg+xml],
    %w[application/xml image/svg+xml],
    %w[application/zip application/java-archive],
    %w[application/zip application/vnd.openxmlformats-officedocument.wordprocessingml.document]
  ].freeze

  # Spoofed uploads: [declared, detected].
  #
  # Siblings sharing a Marcel parent, which the 4.x comparison (declared and
  # detected types plus their parents) accepted.
  SPOOFING_SIBLING_PAIRS = [
    # under text/plain
    %w[text/csv text/x-php],
    %w[text/csv text/x-python],
    %w[text/css text/x-php],
    # under application/xml
    %w[image/svg+xml application/rdf+xml],
    # under application/zip
    %w[application/vnd.openxmlformats-officedocument.wordprocessingml.document application/java-archive],
    %w[application/vnd.openxmlformats-officedocument.spreadsheetml.sheet application/java-archive],
    %w[application/vnd.openxmlformats-officedocument.wordprocessingml.document application/vnd.openxmlformats-officedocument.spreadsheetml.sheet],
    # under application/x-tika-msoffice / application/x-ole-storage
    %w[application/msword application/vnd.ms-excel],
    %w[application/vnd.ms-excel application/msword],
    %w[application/msword application/x-ms-installer]
  ].freeze

  # Unrelated types, rejected by 4.x as well.
  SPOOFING_UNRELATED_PAIRS = [
    %w[application/json text/x-php],
    %w[application/epub+zip application/java-archive],
    %w[video/mp4 video/3gpp],
    %w[image/jpeg text/x-php],
    %w[image/png text/html],
    %w[image/png image/svg+xml],
    %w[image/jpeg application/x-dosexec],
    %w[application/pdf application/x-dosexec],
    %w[application/pdf text/html],
    %w[application/zip application/x-dosexec],
    %w[text/plain text/html],
    %w[text/plain application/x-dosexec],
    %w[video/mp4 application/x-executable],
    %w[audio/mpeg text/x-shellscript],
    %w[text/csv image/svg+xml]
  ].freeze

  # Spoofed fixture files under test/dummy/public/spoofed, with the formats
  # they are uploaded as (extension => declared type) and the backends that
  # must report them as spoofed. Claims absent from a list are accepted on
  # purpose (SPOOFING_DESCENDANT_PAIRS) or are the payload's real type.
  SPOOFING_CLAIMS = {
    jpg: "image/jpeg", png: "image/png", gif: "image/gif", svg: "image/svg+xml",
    pdf: "application/pdf", json: "application/json", xml: "application/xml",
    zip: "application/zip", docx: "application/vnd.openxmlformats-officedocument.wordprocessingml.document",
    xlsx: "application/vnd.openxmlformats-officedocument.spreadsheetml.sheet",
    csv: "text/csv", txt: "text/plain", html: "text/html", mp4: "video/mp4", mp3: "audio/mpeg"
  }.freeze

  ALL_SPOOFING_CLAIMS = SPOOFING_CLAIMS.keys.freeze

  SPOOFED_FIXTURES = {
    "payload.php" => { file: ALL_SPOOFING_CLAIMS - %i[txt], magika: ALL_SPOOFING_CLAIMS - %i[txt] },
    "payload.html" => { file: ALL_SPOOFING_CLAIMS - %i[html], magika: ALL_SPOOFING_CLAIMS - %i[html] },
    "payload_with_script.svg" => { file: ALL_SPOOFING_CLAIMS - %i[svg xml txt], magika: ALL_SPOOFING_CLAIMS - %i[svg xml txt] },
    "payload.sh" => { file: ALL_SPOOFING_CLAIMS, magika: ALL_SPOOFING_CLAIMS },
    # `file` names Python text/x-script.python, which Marcel does not know
    "payload.py" => { file: ALL_SPOOFING_CLAIMS, magika: ALL_SPOOFING_CLAIMS - %i[txt] },
    "payload.exe" => { file: ALL_SPOOFING_CLAIMS, magika: ALL_SPOOFING_CLAIMS },
    "payload.elf" => { file: ALL_SPOOFING_CLAIMS, magika: ALL_SPOOFING_CLAIMS },
    # `file` reports a JAR as application/zip, an ancestor of DOCX / XLSX:
    # only Magika tells them apart
    "payload.jar" => { file: ALL_SPOOFING_CLAIMS - %i[zip docx xlsx], magika: ALL_SPOOFING_CLAIMS - %i[zip] }
  }.freeze

  # Genuine fixtures Magika 1.0 misidentifies, so spoofing_protection: :magika
  # rejects them (4.x did too): HEIC as video/mp4, HTML as text/plain (not a
  # Marcel parent of text/html), the others as application/octet-stream.
  # Prefer :file for those formats.
  MAGIKA_MISDETECTED_FIXTURES = %i[heic avi wmv aac html].freeze

  # Content types browsers / OSes declare that Rails normalizes when it
  # identifies the upload (identify: true, the default for form uploads).
  # (`text/xml` and `audio/x-m4a` are kept by Rails and are not authorized by
  # `:xml` / `:m4a` on Marcel 1: content_type_invalid, before any sniffing.)
  BROWSER_DECLARED_CONTENT_TYPES = {
    jpg: %w[image/pjpeg image/jpg], png: %w[image/x-png], bmp: %w[image/x-ms-bmp image/x-bmp],
    mp3: %w[audio/mp3 audio/mpeg3], wav: %w[audio/wav audio/wave audio/vnd.wave], m4a: %w[audio/m4a],
    webm: %w[audio/webm], pdf: %w[application/x-pdf],
    zip: %w[application/x-zip-compressed application/x-zip], gz: %w[application/x-gzip], rar: %w[application/vnd.rar]
  }.freeze

  def spoofed_fixture(name, claim)
    fixture_file(File.join("spoofed", name), filename: "spoofed.#{claim}", content_type: SPOOFING_CLAIMS.fetch(claim))
  end
end
