# frozen_string_literal: true

# Fixture attachables for the suite. Included and extended via RSpec so helpers
# are available in examples and in example-group bodies (`if:`, `.each` loops).
# Opened Files are registered on the current thread and closed after each example.
module FixtureFiles
  def open_fixture(path, mode = "r")
    register_fixture_io(File.open(path, mode))
  end

  def register_fixture_io(io)
    registered_fixture_ios << io
    io
  end

  def register_uploaded_file(file)
    register_fixture_io(file.tempfile) if file.respond_to?(:tempfile)
    file
  end

  def close_fixture_ios
    registered_fixture_ios.each do |io|
      next unless io.respond_to?(:close)
      next if io.respond_to?(:closed?) && io.closed?

      io.close
    rescue IOError, Errno::EBADF
    end
  ensure
    registered_fixture_ios.clear
  end

  def fixture_file(relative_path, filename:, content_type:)
    {
      io: open_fixture(Rails.root.join("public", relative_path)),
      filename: filename,
      content_type: content_type
    }
  end

  def magika_cli_available?
    FixtureFiles.magika_cli_available?
  end

  def bad_dummy_file
    fixture_file("apple-touch-icon.png", filename: "apple-touch-icon.png", content_type: "text/plain")
  end

  def image_150x150_file
    fixture_file("image_150x150.png", filename: "image_150x150_file.png", content_type: "image/png")
  end
  alias square_image_file image_150x150_file

  # A PNG cut short after its header: the magic bytes still identify it as a PNG,
  # but no image processor can decode it.
  def image_150x150_truncated_file
    fixture_file("image_150x150_truncated.png", filename: "image_150x150_truncated.png", content_type: "image/png")
  end

  def image_500x500_file
    fixture_file("image_500x500.png", filename: "image_500x500_file.png", content_type: "image/png")
  end

  def image_600x600_file
    fixture_file("image_600x600.png", filename: "image_600x600_file.png", content_type: "image/png")
  end

  def image_500x700_file
    fixture_file("image_500x700.png", filename: "image_500x700_file.png", content_type: "image/png")
  end

  def image_700x500_file
    fixture_file("image_700x500.png", filename: "image_700x500_file.png", content_type: "image/png")
  end
  alias landscape_image_file image_700x500_file

  def image_800x600_file
    fixture_file("image_800x600.png", filename: "image_800x600_file.png", content_type: "image/png")
  end

  def image_600x800_file
    fixture_file("image_600x800.png", filename: "image_600x800_file.png", content_type: "image/png")
  end
  alias portrait_image_file image_600x800_file

  def image_1200x900_file
    fixture_file("image_1200x900.png", filename: "image_1200x900_file.png", content_type: "image/png")
  end
  alias is_4_3_image_file image_1200x900_file

  def image_1300x1000_file
    fixture_file("image_1300x1000.png", filename: "image_1300x1000_file.png", content_type: "image/png")
  end

  def image_1920x1080_file
    fixture_file("image_1920x1080.png", filename: "image_1920x1080_file.png", content_type: "image/png")
  end
  alias is_16_9_image_file image_1920x1080_file

  def pdf_150x150_file
    fixture_file("pdf_150x150.pdf", filename: "pdf_150x150_file.pdf", content_type: "application/pdf")
  end
  alias pdf_1_page_file pdf_150x150_file

  # a-chacon / #404: leading space (0x20) before %PDF — libmagic often returns
  # application/octet-stream while Magika and pdf readers still see a PDF.
  def pdf_leading_space_file
    fixture_file("pdf_leading_space.pdf", filename: "pdf_leading_space.pdf", content_type: "application/pdf")
  end

  def pdf_200x300_file
    fixture_file("pdf_200x300.pdf", filename: "pdf_200x300_file.pdf", content_type: "application/pdf")
  end

  def pdf_2_pages_file
    fixture_file("pdf_2_pages.pdf", filename: "pdf_2_pages.pdf", content_type: "application/pdf")
  end

  def pdf_5_pages_file
    fixture_file("pdf_5_pages.pdf", filename: "pdf_5_pages.pdf", content_type: "application/pdf")
  end

  def pdf_7_pages_file
    fixture_file("pdf_7_pages.pdf", filename: "pdf_7_pages.pdf", content_type: "application/pdf")
  end

  def pdf_10_pages_file
    fixture_file("pdf_10_pages.pdf", filename: "pdf_10_pages.pdf", content_type: "application/pdf")
  end

  def tar_file_with_image_content_type
    fixture_file("404.html.tar", filename: "404.png", content_type: "image/png")
  end

  def image_string_io
    {
      io: StringIO.new(File.binread(Rails.root.join("public", "image_1920x1080.png"))),
      filename: "image_1920x1080.png",
      content_type: "image/png"
    }
  end

  def image_file_0ko
    fixture_file("image_file_0ko.png", filename: "image_file_0ko.png", content_type: "image/png")
  end

  def file_1ko
    fixture_file("file_1ko.png", filename: "file_1ko.png", content_type: "image/png")
  end
  alias file_1ko_and_png file_1ko

  def file_2ko
    fixture_file("file_2ko", filename: "file_2ko", content_type: "text/html")
  end

  def file_5ko
    fixture_file("file_5ko", filename: "file_5ko", content_type: "text/html")
  end

  def file_7ko
    fixture_file("file_7ko", filename: "file_7ko", content_type: "text/html")
  end

  def file_7ko_and_jpg
    fixture_file("file_7ko_and_jpg.jpg", filename: "file_7ko_and_jpg", content_type: "image/jpeg")
  end

  def file_10ko
    fixture_file("file_10ko.png", filename: "file_10ko", content_type: "image/png")
  end

  def file_17ko_and_png
    fixture_file("file_17ko_and_png.png", filename: "file_17ko_and_png", content_type: "image/png")
  end

  def file_28ko
    fixture_file("file_28ko.png", filename: "file_28ko", content_type: "image/png")
  end

  def image_150x150_28ko
    fixture_file("image_150x150_28ko.png", filename: "image_150x150_28ko", content_type: "image/png")
  end

  def spoofed_jpeg
    fixture_file("spoofed.jpg", filename: "spoofed.jpg", content_type: "image/jpeg")
  end

  def spoofed_extension_jpeg
    fixture_file(
      File.join("most_common_mime_types", "example.jpeg"),
      filename: "example.png",
      content_type: "image/jpeg"
    )
  end

  def empty_io_file
    {
      io: StringIO.new(""),
      filename: "example.jpeg",
      content_type: "image/jpeg"
    }
  end

  def not_identifiable_io_file
    {
      io: StringIO.new("💎"),
      filename: "example.jpeg",
      content_type: "image/jpeg"
    }
  end

  def audio_file
    fixture_file("audio.mp3", filename: "audio", content_type: "audio/mp3")
  end
  alias audio_1s audio_file

  def audio_0_5s
    fixture_file("audio_0_5s.mp3", filename: "audio_0_5s", content_type: "audio/mp3")
  end

  def audio_2s
    fixture_file("audio_2s.mp3", filename: "audio_2s", content_type: "audio/mp3")
  end

  def audio_5s
    fixture_file("audio_5s.mp3", filename: "audio_5s", content_type: "audio/mp3")
  end

  def audio_7s
    fixture_file("audio_7s.mp3", filename: "audio_7s", content_type: "audio/mp3")
  end

  def audio_10s
    fixture_file("audio_10s.mp3", filename: "audio_10s", content_type: "audio/mp3")
  end

  def video_file
    fixture_file("video.mp4", filename: "video", content_type: "video/mp4")
  end

  def video_with_audio_file
    fixture_file("video_with_audio.mp4", filename: "video_with_audio", content_type: "video/mp4")
  end

  def create_blob_from_file(file)
    ActiveStorage::Blob.create_and_upload!(
      io: file[:io],
      filename: file[:filename],
      content_type: file[:content_type],
      service_name: "test"
    )
  end

  def create_blob(size: 1)
    ActiveStorage::Blob.create_and_upload!(
      io: StringIO.new("a" * size.kilobytes),
      filename: "file_#{size}ko",
      content_type: "text/plain",
      service_name: "test"
    )
  end

  def blob_file_0_5ko
    create_blob(size: 0.5)
  end

  def blob_file_1ko
    create_blob(size: 1)
  end

  def blob_file_2ko
    create_blob(size: 2)
  end

  def blob_file_5ko
    create_blob(size: 5)
  end

  def self.magika_cli_available?
    return @magika_cli_available if defined?(@magika_cli_available)

    @magika_cli_available = system("magika", "--version", out: File::NULL, err: File::NULL)
  end

  private

  def registered_fixture_ios
    Thread.current[:asv_fixture_ios] ||= []
  end
end
