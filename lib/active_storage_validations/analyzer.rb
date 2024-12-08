# frozen_string_literal: true

require_relative 'shared/asv_attachable'
require_relative 'shared/asv_loggable'

module ActiveStorageValidations
  # = Active Storage Validations \Analyzer
  #
  # This is an abstract base class for analyzers, which extract metadata from attachables.
  # See ActiveStorageValidations::Analyzer::ImageAnalyzer for an example of a concrete subclass.
  #
  # Heavily (not to say 100%) inspired by Rails own ActiveStorage::Analyzer
  class Analyzer
    include ASVAttachable
    include ASVLoggable

    attr_reader :attachable

    def initialize(attachable)
      @attachable = attachable
    end

    # Override this method in a concrete subclass. Have it return a Hash of metadata.
    def metadata
      raise NotImplementedError
    end

    private

    def instrument(analyzer, &block)
      ActiveSupport::Notifications.instrument("analyze.active_storage_validations", analyzer: analyzer, &block)
    end
  end
end
