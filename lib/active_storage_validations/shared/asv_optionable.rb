# frozen_string_literal: true

module ActiveStorageValidations
  # ActiveStorageValidations::ASVOptionable
  #
  # Helper method to flatten the validator options.
  module ASVOptionable
    extend ActiveSupport::Concern

    private

    def flatten_options(record, options = self.options, available_checks = self.class::AVAILABLE_CHECKS)
      case options
      when Hash
        options.merge(options) do |key, value|
          available_checks&.exclude?(key) ? {} : flatten_options(record, value, nil)
        end
      when Array
        options.map { |option| flatten_options(record, option, available_checks) }
      else
        options.is_a?(Proc) ? options.call(record) : options
      end
    end
  end
end
