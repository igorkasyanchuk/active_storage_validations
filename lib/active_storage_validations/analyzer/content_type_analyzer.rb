# frozen_string_literal: true

module ActiveStorageValidations
  # = ActiveStorageValidations ContentType \Analyzer
  #
  # Abstract base for content-type sniffers used by +spoofing_protection+.
  # Concrete backends:
  #
  #   ActiveStorageValidations::Analyzer::ContentTypeAnalyzer::File.new(attachable).content_type
  #   # => { content_type: "image/png", content_type_backend: "file" }
  #
  #   ActiveStorageValidations::Analyzer::ContentTypeAnalyzer::Magika.new(attachable).content_type
  #   # => { content_type: "image/png", content_type_backend: "magika" }
  class Analyzer::ContentTypeAnalyzer < Analyzer
    def content_type
      read_media do |media|
        {
          content_type: media,
          content_type_backend: backend.to_s
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
            logger.info "Skipping content_type analysis because #{backend} doesn't support the file"
            nil
          end
        ensure
          tempfile.close
        end
      end
    rescue Errno::ENOENT
      raise missing_backend_error
    end

    def backend
      raise NotImplementedError
    end

    def missing_backend_error
      raise NotImplementedError
    end
  end
end
