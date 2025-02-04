# frozen_string_literal: true

require "active_support/concern"

module ActiveStorageValidations
  module Matchers
    module ASVRspecable
      extend ActiveSupport::Concern

      def initialize_rspecable
        @failure_message_artefacts = []
      end

      def description
        raise NotImplementedError, "#{self.class} did not define #{__method__}"
      end

      def failure_message
        raise NotImplementedError, "#{self.class} did not define #{__method__}"
      end

      def failure_message_when_negated
        failure_message.sub(/is expected to validate/, "is expected not to validate")
      end
    end
  end
end
