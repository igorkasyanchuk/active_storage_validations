# frozen_string_literal: true

require "active_support/concern"

module ActiveStorageValidations
  module Matchers
    module ASVRspecable
      extend ActiveSupport::Concern

      # Qualifiers contributed by the shared option concerns, in this order.
      OPTION_DESCRIPTIONS = %i[
        allow_blank_description
        custom_message_description
        context_description
        except_on_description
        timeout_description
        spoofing_protection_description
      ].freeze

      def initialize_rspecable
        @failure_message_artefacts = []
      end

      # The chained qualifiers are part of the description, so RSpec one-liners
      # and shoulda-context test names tell two chains on one attribute apart.
      def description
        [ base_description, *chain_descriptions, *option_descriptions ].join(", ")
      end

      def failure_message
        raise NotImplementedError, "#{self.class} did not define #{__method__}"
      end

      def failure_message_when_negated
        failure_message.sub(/is expected to validate/, "is expected not to validate")
      end

      private

      def base_description
        raise NotImplementedError, "#{self.class} did not define #{__method__}"
      end

      def chain_descriptions
        []
      end

      def option_descriptions
        OPTION_DESCRIPTIONS.filter_map { |method| send(method) if respond_to?(method, true) }
      end

      # Record a probe whose outcome is not the expected one. Probes the
      # matcher expects the validator to reject are not issues when rejected.
      def add_failure_message_artefact(probe, passed:)
        @failure_message_artefacts << { probe: probe, passed: passed }
        false
      end

      def build_failure_message(message)
        rejected, accepted = @failure_message_artefacts.partition { |artefact| !artefact[:passed] }
        return if rejected.empty? && accepted.empty?

        message << "  but there seem to have issues with the matcher methods you used, since:"
        append_failure_message_artefacts(message, rejected, "failed", "passed")
        append_failure_message_artefacts(message, accepted, "passed", "failed")
      end

      def append_failure_message_artefacts(message, artefacts, outcome, expected_outcome)
        return if artefacts.empty?

        artefacts.each do |artefact|
          message << "  validation #{outcome} when provided with #{artefact[:probe]}"
        end
        message << "  whereas it should have #{expected_outcome}"
      end
    end
  end
end
