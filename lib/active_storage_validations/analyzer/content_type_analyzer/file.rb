# frozen_string_literal: true

module ActiveStorageValidations
  # Content-type sniffer using the UNIX {file}[https://en.wikipedia.org/wiki/File_(command)] command.
  #
  # Override the binary path with +ActiveStorage.paths[:file]+.
  class Analyzer::ContentTypeAnalyzer::File < Analyzer::ContentTypeAnalyzer
    # libmagic never looks past the first MiB of a file (its +bytes+ parameter,
    # 1048576 by default), so persisted blobs are only downloaded up to that
    # point. Magika also samples the end of the file and keeps the full download.
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
        result = run_command(file_path, "-b", "--mime-type", path, payload: payload)
        result.success? ? result.stdout.strip : nil
      end
    end

    def file_path
      ActiveStorage.paths[:file] || "file"
    end

    def missing_backend_error
      CommandLineToolNotInstalledError.new("file command-line tool is not installed")
    end
  end
end
