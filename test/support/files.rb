def dummy_file
  {
    io: File.open(Rails.root.join('public', 'apple-touch-icon.png')),
    filename: 'dummy_file.png',
    content_type: 'image/png'
  }
end

def pdf_file
  {
    io: File.open(Rails.root.join('public', 'pdf.pdf')),
    filename: 'pdf_file.pdf',
    content_type: 'application/pdf'
  }
end

def bad_dummy_file
  {
    io: File.open(Rails.root.join('public', 'apple-touch-icon.png')),
    filename: 'bad_dummy_file.png',
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

def html_file
  {
    io: File.open(Rails.root.join('public', '500.html')),
    filename: 'html_file.html',
    content_type: 'text/html'
  }
end

def webp_file
  {
    io: File.open(Rails.root.join('public', '1_sm_webp.png')),
    filename: '1_sm_webp.png',
    content_type: 'image/webp'
  }
end

def webp_file_wrong
  {
    io: File.open(Rails.root.join('public', '1_sm_webp.png')),
    filename: '1_sm_webp.png',
    content_type: 'image/png'
  }
end

def docx_file
  {
    io: File.open(Rails.root.join('public', 'example.docx')),
    filename: 'example.docx',
    content_type: 'application/vnd.openxmlformats-officedocument.wordprocessingml.document'
  }
end

def sheet_file
  {
    io: File.open(Rails.root.join('public', 'example.xlsx')),
    filename: 'example.xlsx',
    content_type: 'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet'
  }
end

def pages_file
  {
    io: File.open(Rails.root.join('public', 'example.pages')),
    filename: 'example.pages',
    content_type: 'application/vnd.apple.pages'
  }
end

def png_file
  {
    io: File.open(Rails.root.join('public', 'example.png')),
    filename: 'example.png',
    content_type: 'image/png'
  }
end

def gif_file
  {
    io: File.open(Rails.root.join('public', 'example.gif')),
    filename: 'example.gif',
    content_type: 'image/gif'
  }
end

def numbers_file
  {
    io: File.open(Rails.root.join('public', 'example.numbers')),
    filename: 'example.numbers',
    content_type: 'application/vnd.apple.numbers'
  }
end

def tar_file
  {
    io: File.open(Rails.root.join('public', '404.html.tar')),
    filename: '404.html.tar',
    content_type: 'application/x-tar'
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
    io: File.open(Rails.root.join('public', 'file_1ko')),
    filename: 'file_1ko',
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
    io: File.open(Rails.root.join('public', 'file_10ko')),
    filename: 'file_10ko',
    content_type: 'text/html'
  }
end

def file_17ko_and_png
  {
    io: File.open(Rails.root.join('public', 'file_17ko_and_png.png')),
    filename: 'file_17ko_and_png',
    content_type: 'image/png'
  }
end
