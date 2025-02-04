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
    def validate_dimensions_of(attribute_name)
      DimensionValidatorMatcher.new(attribute_name)
    end

    class DimensionValidatorMatcher
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
        @width_min = @width_max = @height_min = @height_max = nil
      end

      def description
        "validate the image dimensions of :#{@attribute_name}"
      end

      def failure_message
        message = [ "is expected to validate dimensions of :#{@attribute_name}" ]
        build_failure_message(message)
        message.join("\n")
      end

      def width(width)
        @width_min = @width_max = width
        self
      end

      def width_min(width)
        @width_min = width
        self
      end

      def width_max(width)
        @width_max = width
        self
      end

      def width_between(range)
        @width_min, @width_max = range.first, range.last
        self
      end

      def height(height)
        @height_min = @height_max = height
        self
      end

      def height_min(height)
        @height_min = height
        self
      end

      def height_max(height)
        @height_max = height
        self
      end

      def height_between(range)
        @height_min, @height_max = range.first, range.last
        self
      end

      def matches?(subject)
        @subject = subject.is_a?(Class) ? subject.new : subject

        is_a_valid_active_storage_attribute? &&
          is_context_valid? &&
          is_allowing_blank? &&
          is_custom_message_valid? &&
          width_not_smaller_than_min? &&
          width_larger_than_min? &&
          width_smaller_than_max? &&
          width_not_larger_than_max? &&
          width_equals? &&
          height_not_smaller_than_min? &&
          height_larger_than_min? &&
          height_smaller_than_max? &&
          height_not_larger_than_max? &&
          height_equals?
      end

      protected

      def build_failure_message(message)
        return unless @failure_message_artefacts.present?

        message << "  but there seem to have issues with the matcher methods you used, since:"
        @failure_message_artefacts.each do |error_case|
          message << "  validation failed when provided with a #{error_case[:width]}x#{error_case[:height]}px test image"
        end
        message << "  whereas it should have passed"
      end

      def valid_width
        ((@width_min || 0) + (@width_max || 2000)) / 2
      end

      def valid_height
        ((@height_min || 0) + (@height_max || 2000)) / 2
      end

      def width_not_smaller_than_min?
        @width_min.nil? || !passes_validation_with_dimensions(@width_min - 1, valid_height)
      end

      def width_larger_than_min?
        @width_min.nil? || @width_min == @width_max || passes_validation_with_dimensions(@width_min + 1, valid_height)
      end

      def width_smaller_than_max?
        @width_max.nil? || @width_min == @width_max || passes_validation_with_dimensions(@width_max - 1, valid_height)
      end

      def width_not_larger_than_max?
        @width_max.nil? || !passes_validation_with_dimensions(@width_max + 1, valid_height)
      end

      def width_equals?
        @width_min.nil? || @width_min != @width_max || passes_validation_with_dimensions(@width_min, valid_height)
      end

      def height_not_smaller_than_min?
        @height_min.nil? || !passes_validation_with_dimensions(valid_width, @height_min - 1)
      end

      def height_larger_than_min?
        @height_min.nil? || @height_min == @height_max || passes_validation_with_dimensions(valid_width, @height_min + 1)
      end

      def height_smaller_than_max?
        @height_max.nil? || @height_min == @height_max || passes_validation_with_dimensions(valid_width, @height_max - 1)
      end

      def height_not_larger_than_max?
        @height_max.nil? || !passes_validation_with_dimensions(valid_width, @height_max + 1)
      end

      def height_equals?
        @height_min.nil? || @height_min != @height_max || passes_validation_with_dimensions(valid_width, @height_min)
      end

      def passes_validation_with_dimensions(width, height)
        mock_dimensions_for(attach_file, width, height) do
          validate
          detach_file
          is_valid? || add_failure_message_artefact(width, height)
        end
      end

      def add_failure_message_artefact(width, height)
        @failure_message_artefacts << { width: width, height: height }
        false
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
    end
  end
end
