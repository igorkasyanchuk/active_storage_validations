# frozen_string_literal: true

module ActiveStorageValidations
  # Content-type sniffer using the UNIX {file}[https://en.wikipedia.org/wiki/File_(command)] command.
  #
  # Override the binary path with +ActiveStorage.paths[:file]+.
  class Analyzer::ContentTypeAnalyzer::File < Analyzer::ContentTypeAnalyzer
    # Persisted blobs are only downloaded up to this point, and libmagic is
    # pinned to the same +bytes+ parameter (-P bytes=…): its default grew from
    # 1 MiB to 7 MiB in recent releases, so without the pin an uploaded file
    # could be sniffed on more bytes than the same file as a blob. Magika also
    # samples the end of the file and keeps the full download.
    # (Plain integer: core extensions such as Integer#megabyte are not
    # guaranteed to be loaded when the gem is required.)
    LIBMAGIC_BYTES_LIMIT = 1_048_576

    private

    def backend
      :file
    end

    def media_path_options
      { max_bytes: LIBMAGIC_BYTES_LIMIT }
    end

    def media_from_path(path)
      instrument("file") do |payload|
        result = run_command(*file_command(path), payload: payload)
        result.success? ? result.stdout.strip : nil
      end
    end

    # -E: exit non-zero on filesystem errors. Without it +file+ prints
    # "cannot open `…'" on stdout with status 0, which would be cached as the
    # detected content type. -P needs file >= 5.26, -E file >= 5.18.
    def file_command(path)
      [ file_path, "-E", "-P", "bytes=#{LIBMAGIC_BYTES_LIMIT}", "-b", "--mime-type", path ]
    end

    def file_path
      ActiveStorage.paths[:file] || "file"
    end

    def missing_backend_error
      CommandLineToolNotInstalledError.new("file command-line tool is not installed")
    end
  end
end
