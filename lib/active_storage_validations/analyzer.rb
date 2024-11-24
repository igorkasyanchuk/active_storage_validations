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

    # Implement this method in a concrete subclass. Have it return true when given an attachable from which
    # the analyzer can extract metadata.
    def self.accept?(attachable)
      false
    end

    # Returns true if the attachable media_type matches, like image?(attachable) returns
    # true for 'image/png'
    class << self
      %w[
        image
        audio
        video
      ].each do |media_type|
        define_method(:"#{media_type}?") do |attachable|
          attachable_content_type(attachable).start_with?(media_type)
        end
      end

      def attachable_content_type(attachable)
        new(attachable).send(:attachable_content_type, attachable)
      end
    end

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
