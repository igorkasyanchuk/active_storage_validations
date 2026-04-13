# frozen_string_literal: true

module ActiveStorageValidations
  # ActiveStorageValidations::ASVOrchestrable
  #
  # Helper methods for heavyweight validators that benefit from orchestration.
  module ASVOrchestrable
    extend ActiveSupport::Concern

    class_methods do
      def validation_steps(options)
        [ options ] # default: single step
      end
    end


    included do
      def warn_if_used_without_orchestration(attribute)
        return if options[:_asv_orchestrated]

        deprecator = ActiveStorageValidations.deprecator

        deprecator.warn(
          "Using `validates :#{attribute}, #{self.class.to_sym}: ...` directly is deprecated. " \
          "Please use `validate_attached :#{attribute}, #{self.class.to_sym}: ...` instead." \
          " (will be removed in version #{deprecator.deprecation_horizon})"
        )
      end
    end
  end
end
