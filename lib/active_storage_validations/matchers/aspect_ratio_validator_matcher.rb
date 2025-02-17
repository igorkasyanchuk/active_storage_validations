# frozen_string_literal: true

require_relative "shared/asv_active_storageable"
require_relative "shared/asv_allow_blankable"
require_relative "shared/asv_attachable"
require_relative "shared/asv_contextable"
require_relative "shared/asv_messageable"
require_relative "shared/asv_rspecable"
require_relative "shared/asv_validatable"

module ActiveStorageValidations
  module Matchers
    def validate_aspect_ratio_of(attribute_name)
      AspectRatioValidatorMatcher.new(attribute_name)
    end

    class AspectRatioValidatorMatcher
      include ASVActiveStorageable
      include ASVAllowBlankable
      include ASVAttachable
      include ASVContextable
      include ASVMessageable
      include ASVRspecable
      include ASVValidatable

      def initialize(attribute_name)
        initialize_allow_blankable
        initialize_contextable
        initialize_messageable
        initialize_rspecable
        @attribute_name = attribute_name
        @allowed_aspect_ratios = @rejected_aspect_ratios = []
      end

      def description
        "validate the aspect ratios allowed on :#{@attribute_name}."
      end

      def failure_message
        "is expected to validate aspect ratio of :#{@attribute_name}"
      end

      def allowing(*aspect_ratios)
        @allowed_aspect_ratios = aspect_ratios.flatten
        self
      end

      def rejecting(*aspect_ratios)
        @rejected_aspect_ratios = aspect_ratios.flatten
        self
      end

      def matches?(subject)
        @subject = subject.is_a?(Class) ? subject.new : subject

        is_a_valid_active_storage_attribute? &&
          is_context_valid? &&
          is_allowing_blank? &&
          is_custom_message_valid? &&
          all_allowed_aspect_ratios_allowed? &&
          all_rejected_aspect_ratios_rejected?
      end

      protected

      def all_allowed_aspect_ratios_allowed?
        @allowed_aspect_ratios_not_allowed ||= @allowed_aspect_ratios.reject { |aspect_ratio| aspect_ratio_allowed?(aspect_ratio) }
        @allowed_aspect_ratios_not_allowed.empty?
      end

      def all_rejected_aspect_ratios_rejected?
        @rejected_aspect_ratios_not_rejected ||= @rejected_aspect_ratios.select { |aspect_ratio| aspect_ratio_allowed?(aspect_ratio) }
        @rejected_aspect_ratios_not_rejected.empty?
      end

      def aspect_ratio_allowed?(aspect_ratio)
        width, height = valid_width_and_height_for(aspect_ratio)

        mock_dimensions_for(attach_file, width, height) do
          validate
          detach_file
          is_valid?
        end
      end

      def is_custom_message_valid?
        return true unless @custom_message

        mock_dimensions_for(attach_file, -1, -1) do
          validate
          detach_file
          has_an_error_message_which_is_custom_message?
        end
      end

      def mock_dimensions_for(attachment, width, height)
        Matchers.mock_metadata(attachment, { width: width, height: height }) do
          yield
        end
      end

      def valid_width_and_height_for(aspect_ratio)
        case aspect_ratio
        when :square then [ 100, 100 ]
        when :portrait then [ 100, 200 ]
        when :landscape then [ 200, 100 ]
        when validator_class::ASPECT_RATIO_REGEX
          aspect_ratio =~ validator_class::ASPECT_RATIO_REGEX
          x = Regexp.last_match(1).to_i
          y = Regexp.last_match(2).to_i

          [ 100 * x, 100 * y ]
        else
          [ -1, -1 ]
        end
      end
    end
  end
end
