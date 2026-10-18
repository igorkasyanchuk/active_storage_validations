# frozen_string_literal: true

module ActiveStorageValidations
  # = ActiveStorageValidations PDF \Analyzer
  #
  # Extracts the following from a pdf attachable:
  #
  # * Width (pts) => for the first page only, as displayed (/Rotate applied)
  # * Height (pts) => for the first page only, as displayed (/Rotate applied)
  # * Pages (integer) => number of pages in the pdf
  #
  # Example:
  #
  #   ActiveStorageValidations::Analyzer::PdfAnalyzer.new(attachable).metadata
  #   # => { width: 150, height: 150, pages: 1 }
  #
  # This analyzer requires the {poppler}[https://pdf2image.readthedocs.io/en/latest/installation.html] system library, which is not provided by \Rails.
  class Analyzer::PdfAnalyzer < Analyzer
    # pdfinfo reports e.g. "595.276 x 841.89 pts (A4)". Capture the full
    # integer or decimal so extra fractional digits are not split into a
    # second number (which would make height 8 for A4).
    PAGE_SIZE_NUMBER = /\d+(?:\.\d+)?/

    def metadata
      read_media do |media|
        {
          width: positive_measurement(width),
          height: positive_measurement(height),
          pages: pages
        }.compact
      end
    end

    private

    def read_media
      create_media_tempfile do |tempfile|
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
      instrument(File.basename(pdfinfo_path)) do |payload|
        result = run_command(pdfinfo_path, path, payload: payload)
        result.success? ? stdout_to_hash(result.stdout) : nil
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
      page_size_in_points[rotated? ? 1 : 0]
    end

    def height
      page_size_in_points[rotated? ? 0 : 1]
    end

    # pdfinfo reports the MediaBox as stored, plus the page /Rotate ("Page rot:
    # 90"). Swap the sides of quarter-turned pages so width / height describe
    # the page as displayed, like the image and video analyzers do.
    def rotated?
      @media["page_rot"].to_i % 180 == 90
    end

    def page_size_in_points
      @media["page_size"].to_s.scan(PAGE_SIZE_NUMBER).map(&:to_i)
    end

    def pages
      return unless @media.key?("pages")

      positive_measurement(@media["pages"].to_i)
    end

    # 0 is not a usable measurement (PagesValidator / processable_file treat
    # it as a miss). Omit it so Hash#compact does not cache a fake success.
    def positive_measurement(value)
      value if value.to_i.positive?
    end
  end
end
