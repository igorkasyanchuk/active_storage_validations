# frozen_string_literal: true

require "json"

module ActiveStorageValidations
  # Content-type sniffer using the Google {Magika}[https://github.com/google/magika] CLI.
  #
  # Override the binary path with +ActiveStorage.paths[:magika]+.
  class Analyzer::ContentTypeAnalyzer::Magika < Analyzer::ContentTypeAnalyzer
    class CommandLineToolNotInstalledError < StandardError; end

    private

    def backend
      :magika
    end

    def media_from_path(path)
      instrument("magika") do |payload|
        result = run_command(magika_path, "--json", path, payload: payload)
        result.success? ? mime_type_from_magika_json(result.stdout) : nil
      end
    end

    def mime_type_from_magika_json(stdout)
      parsed = JSON.parse(stdout)
      entry = parsed.is_a?(Array) ? parsed.first : parsed
      return nil unless entry.is_a?(Hash)
      return nil unless entry.dig("result", "status") == "ok"

      entry.dig("result", "value", "output", "mime_type").presence
    rescue JSON::ParserError
      nil
    end

    def magika_path
      ActiveStorage.paths[:magika] || "magika"
    end

    def missing_backend_error
      CommandLineToolNotInstalledError.new("magika command-line tool is not installed")
    end
  end
end
