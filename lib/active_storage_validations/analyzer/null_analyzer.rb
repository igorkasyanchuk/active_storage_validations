# frozen_string_literal: true

module ActiveStorageValidations
  # = ActiveStorageValidations Null Analyzer
  #
  # This is a fallback analyzer when the attachable media type is not supported
  # by our gem.
  #
  # Example:
  #
  #   ActiveStorageValidations::Analyzer::NullAnalyzer.new(attachable).metadata
  #   # => {}
  class Analyzer::NullAnalyzer < Analyzer
    def metadata
      {}
    end
  end
end
