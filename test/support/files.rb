def bad_dummy_file
  {
    io: File.open(Rails.root.join('public', 'apple-touch-icon.png')),
    filename: 'apple-touch-icon.png',
    content_type: 'text/plain'
  }
end

def image_150x150_file
  {
    io: File.open(Rails.root.join('public', 'image_150x150.png')),
    filename: 'image_150x150_file.png',
    content_type: 'image/png'
  }
end

def image_700x500_file
  {
    io: File.open(Rails.root.join('public', 'image_700x500.png')),
    filename: 'image_700x500_file.png',
    content_type: 'image/png'
  }
end

def image_800x600_file
  {
    io: File.open(Rails.root.join('public', 'image_800x600.png')),
    filename: 'image_800x600_file.png',
    content_type: 'image/png'
  }
end

def image_600x800_file
  {
    io: File.open(Rails.root.join('public', 'image_600x800.png')),
    filename: 'image_600x800_file.png',
    content_type: 'image/png'
  }
end

def image_1200x900_file
  {
    io: File.open(Rails.root.join('public', 'image_1200x900.png')),
    filename: 'image_1200x900_file.png',
    content_type: 'image/png'
  }
end

def image_1300x1000_file
  {
    io: File.open(Rails.root.join('public', 'image_1300x1000.png')),
    filename: 'image_1300x1000_file.png',
    content_type: 'image/png'
  }
end

def image_1920x1080_file
  {
    io: File.open(Rails.root.join('public', 'image_1920x1080.png')),
    filename: 'image_1920x1080_file.png',
    content_type: 'image/png'
  }
end

def tar_file_with_image_content_type
  {
    io: File.open(Rails.root.join('public', '404.html.tar')),
    filename: '404.png',
    content_type: 'image/png'
  }
end

def image_string_io
  string_io = StringIO.new().tap {|io| io.binmode }
  IO.copy_stream(File.open(Rails.root.join('public', 'image_1920x1080.png')), string_io)
  string_io.rewind

  {
    io: string_io,
    filename: 'image_1920x1080.png',
    content_type: 'image/png'
  }
end

def image_file_0ko
  {
    io: File.open(Rails.root.join('public', 'image_file_0ko.png')),
    filename: 'image_file_0ko.png',
    content_type: 'image/png'
  }
end

def file_1ko
  {
    io: File.open(Rails.root.join('public', 'file_1ko.png')),
    filename: 'file_1ko.png',
    content_type: 'image/png'
  }
end
alias :file_1ko_and_png :file_1ko

def file_2ko
  {
    io: File.open(Rails.root.join('public', 'file_2ko')),
    filename: 'file_2ko',
    content_type: 'text/html'
  }
end

def file_5ko
  {
    io: File.open(Rails.root.join('public', 'file_5ko')),
    filename: 'file_5ko',
    content_type: 'text/html'
  }
end

def file_7ko
  {
    io: File.open(Rails.root.join('public', 'file_7ko')),
    filename: 'file_7ko',
    content_type: 'text/html'
  }
end

def file_7ko_and_jpg
  {
    io: File.open(Rails.root.join('public', 'file_7ko_and_jpg.jpg')),
    filename: 'file_7ko_and_jpg',
    content_type: 'image/jpg'
  }
end

def file_10ko
  {
    io: File.open(Rails.root.join('public', 'file_10ko.png')),
    filename: 'file_10ko',
    content_type: 'image/png'
  }
end

def file_17ko_and_png
  {
    io: File.open(Rails.root.join('public', 'file_17ko_and_png.png')),
    filename: 'file_17ko_and_png',
    content_type: 'image/png'
  }
end

def spoofed_jpg
  {
    io: File.open(Rails.root.join('public', 'spoofed.jpg')),
    filename: 'spoofed.jpg',
    content_type: 'spoofed.jpg'
  }
end

def spoofed_extension_jpeg
  {
    io: File.open(Rails.root.join('public', 'most_common_mime_types', 'example.jpeg')),
    filename: 'example.png',
    content_type: 'image/jpeg'
  }
end

def empty_io_file
  {
    io: StringIO.new(''),
    filename: 'example.jpeg',
    content_type: 'image/jpeg'
  }
end

def not_identifiable_io_file
  {
    io: StringIO.new('💎'),
    filename: 'example.jpeg',
    content_type: 'image/jpeg'
  }
end

def create_blob_from_file(file)
  ActiveStorage::Blob.create_and_upload!(
    io: file[:io],
    filename: file[:filename],
    content_type: file[:content_type],
    service_name: 'test'
  )
end

def create_blob(size: 1)
  ActiveStorage::Blob.create_and_upload!(
    io: StringIO.new('a' * size.kilobytes),
    filename: "file_#{size}ko",
    content_type: 'text/plain',
    service_name: 'test'
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
