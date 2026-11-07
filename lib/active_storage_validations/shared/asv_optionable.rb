# frozen_string_literal: true

module ActiveStorageValidations
  # ActiveStorageValidations::ASVOptionable
  #
  # Helper method to flatten the validator options: keeps the validator's
  # check options (AVAILABLE_CHECKS) and resolves the Procs they may hold.
  # Rails options (:message, :if, …) and gem configuration (:timeout, …) are
  # left out since they are never part of the comparison.
  module ASVOptionable
    extend ActiveSupport::Concern

    private

    def set_flat_options(record)
      flatten_options(record, self.options)
    end

    def flatten_options(record, options, available_checks = self.class::AVAILABLE_CHECKS)
      case options
      when Hash
        checks = available_checks ? options.slice(*available_checks) : options
        checks.transform_values { |value| flatten_options(record, value, nil) }
      when Array
        options.map { |option| flatten_options(record, option, available_checks) }
      else
        if options.is_a?(Proc)
          options.arity == 0 ? options.call : options.call(record)
        else
          options
        end
      end
    end

    # Integer 0 is a real bound (`max: 0`, `equal_to: 0`). `.present?` / truthiness
    # treat it as absent, so the check would be skipped.
    def bound_present?(flat_options, key)
      !flat_options[key].nil?
    end
  end
end
