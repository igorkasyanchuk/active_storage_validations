# frozen_string_literal: true

module ActiveStorageValidations
  # Content-type sniffer using the UNIX {file}[https://en.wikipedia.org/wiki/File_(command)] command.
  #
  # Override the binary path with +ActiveStorage.paths[:file]+.
  class Analyzer::ContentTypeAnalyzer::File < Analyzer::ContentTypeAnalyzer
    class CommandLineToolNotInstalledError < StandardError; end

    private

    def backend
      :file
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
