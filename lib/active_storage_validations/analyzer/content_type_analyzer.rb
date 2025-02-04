# frozen_string_literal: true

require "open3"

module ActiveStorageValidations
  # = ActiveStorageValidations ContentType \Analyzer
  #
  # Extracts the content type from an attachable. This is used to prevent content
  # type spoofing.
  #
  # Example:
  #
  #   ActiveStorageValidations::Analyzer::ContentTypeAnalyzer.new(attachable).content_type
  #   # => { content_type: "image/png" }
  #
  # This analyzer requires the {UNIX file}[https://en.wikipedia.org/wiki/File_(command)] command, which is not provided by \Rails. While it is available on most UNIX distributions, it may need to be installed explicitly on minimal or custom setups.
  class Analyzer::ContentTypeAnalyzer < Analyzer
    class FileCommandLineToolNotInstalledError < StandardError; end

    def content_type
      read_media do |media|
        {
          content_type: media
        }
      end
    end

    private

    def read_media
      Tempfile.create(binmode: true) do |tempfile|
        begin
          if media(tempfile).present?
            yield media(tempfile)
          else
            logger.info "Skipping file content_type analysis because Linux file command doesn't support the file"
            nil
          end
        ensure
          tempfile.close
        end
      end
    rescue Errno::ENOENT
      raise FileCommandLineToolNotInstalledError, "file command-line tool is not installed"
    end

    def media_from_path(path)
      instrument("file") do
        stdout, status = Open3.capture2(
          "file",
          "-b",
          "--mime-type",
          path
        )

        status.success? ? stdout.strip : nil
      end
    end
  end
end
