# frozen_string_literal: true

require "open3"

module ActiveStorageValidations
  # = ActiveStorageValidations PDF \Analyzer
  #
  # Extracts the following from a pdf attachable:
  #
  # * Width (pts) => for the first page only
  # * Height (pts) => for the first page only
  # * Pages (integer) => number of pages in the pdf
  #
  # Example:
  #
  #   ActiveStorageValidations::Analyzer::PdfAnalyzer.new(attachable).metadata
  #   # => { width: 150, height: 150, pages: 1 }
  #
  # This analyzer requires the {poppler}[https://pdf2image.readthedocs.io/en/latest/installation.html] system library, which is not provided by \Rails.
  class Analyzer::PdfAnalyzer < Analyzer
    def metadata
      read_media do |media|
        {
          width: width,
          height: height,
          pages: pages
        }.compact
      end
    end

    private

    def read_media
      Tempfile.create(binmode: true) do |tempfile|
        begin
          if media(tempfile).present?
            yield media(tempfile)
          else
            logger.info "Skipping pdf file metadata analysis because poppler doesn't support the file"
            {}
          end
        ensure
          tempfile.close
        end
      end
    rescue Errno::ENOENT
      logger.info "Skipping pdf file metadata analysis because poppler isn't installed"
      {}
    end

    def media_from_path(path)
      instrument(File.basename(pdfinfo_path)) do
        stdout, _stderr, status = Open3.capture3(
          pdfinfo_path,
          path
        )

        status.success? ? stdout_to_hash(stdout) : nil
      end
    end

    def stdout_to_hash(stdout)
      stdout.lines.each_with_object({}) do |line, hash|
        key, value = line.strip.split(":", 2)
        hash[normalize_stdout_key(key)] = value.strip if key && value
      end
    end

    def normalize_stdout_key(key)
      key.strip.underscore.gsub(/\s+/, "_").gsub(/"/, "")
    end

    def pdfinfo_path
      ActiveStorage.paths[:pdfinfo] || "pdfinfo"
    end

    def width
      @media["page_size"].scan(/\d+/)[0].to_i
    end

    def height
      @media["page_size"].scan(/\d+/)[1].to_i
    end

    def pages
      @media["pages"].to_i
    end
  end
end
