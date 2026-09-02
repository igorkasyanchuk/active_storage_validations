# frozen_string_literal: true

require_relative "shared/asv_attachable"
require_relative "shared/asv_commandable"
require_relative "shared/asv_loggable"

module ActiveStorageValidations
  # = Active Storage Validations \Analyzer
  #
  # This is an abstract base class for analyzers, which extract metadata from attachables.
  # See ActiveStorageValidations::Analyzer::VideoAnalyzer for an example of a concrete subclass.
  #
  # Heavily (not to say 100%) inspired by Rails own ActiveStorage::Analyzer
  class Analyzer
    include ASVAttachable
    include ASVCommandable
    include ASVLoggable

    attr_reader :attachable

    def initialize(attachable, timeout: ActiveStorageValidations.command_timeout)
      @attachable = attachable
      @timeout = timeout
    end

    # Override this method in a concrete subclass. Have it return a String content type.
    def content_type
      raise NotImplementedError
    end

    # Override this method in a concrete subclass. Have it return a Hash of metadata.
    def metadata
      raise NotImplementedError
    end

    private

    # Override this method in a concrete subclass. Have it yield a media object.
    def read_media
      raise NotImplementedError
    end

    def media(tempfile)
      @media ||= wrap_attachable(@attachable).with_media_path(tempfile) do |path|
        media_from_path(path)
      end
    end

    # Override this method in a concrete subclass. Have it return a media object.
    def media_from_path(path)
      raise NotImplementedError
    end

    def timeout_in_seconds
      return nil if @timeout.nil?

      @timeout.to_f
    end

    def instrument(analyzer)
      payload = {
        analyzer: analyzer,
        command: analyzer,
        timeout: timeout_in_seconds,
        timed_out: false
      }

      ActiveSupport::Notifications.instrument("analyze.active_storage_validations", payload) do
        started_at = monotonic_time
        result = yield payload
        payload[:duration] = monotonic_time - started_at
        result
      end
    end

    def mark_timed_out!(payload, command)
      payload[:timed_out] = true if payload
      ActiveSupport::Notifications.instrument(
        "timeout.active_storage_validations",
        analyzer: payload&.[](:analyzer) || command,
        command: command,
        timeout: timeout_in_seconds
      )
      logger.info "Skipping file analysis because #{command} timed out after #{timeout_in_seconds} seconds"
    end
  end
end
