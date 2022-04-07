# frozen_string_literal: true

ASPECT_RATIO_REGEX = /is_(\d*)_(\d*)/.freeze
VALID_ASPECT_RATIOS = %i(square portrait landscape).freeze

module ActiveStorageValidations
  module Matchers
    def validate_aspect_ratio_of(name, expected_aspect_ratio)
      AspectRatioValidatorMatcher.new(name, expected_aspect_ratio)
    end

    class AspectRatioValidatorMatcher
      def initialize(attribute_name, expected_aspect_ratio)
        @attribute_name = attribute_name
        @expected_aspect_ratio = expected_aspect_ratio
      end

      def description
        "validate if #{attribute_name} have aspect ratio of #{expected_aspect_ratio}."
      end

      def allowing(*types)
        @allowed_types = types.flatten
        self
      end

      def rejecting(*types)
        @rejected_types = types.flatten
        self
      end

      def matches?(subject)
        @subject = subject.is_a?(Class) ? subject.new : subject
        responds_to_methods &&
          valid_expected_aspect_ratio &&
          valid_when_correct_aspect_ratio &&
          invalid_when_incorrect_aspect_ratio
      end

      def failure_message
        @failure_message
      end

      protected

      def responds_to_methods
        if @subject.respond_to?(attribute_name) &&
            @subject.public_send(attribute_name).respond_to?(:attach) &&
            @subject.public_send(attribute_name).respond_to?(:detach)

          true
        else
          @failure_message = 'Invalid attribute for aspect ratio validation.'
          false
        end
      end

      def valid_expected_aspect_ratio
        if VALID_ASPECT_RATIOS.include?(expected_aspect_ratio) ||
           expected_aspect_ratio.match?(ASPECT_RATIO_REGEX)

          true
        else
          @failure_message = <<~FAILURE_MESSAGE
            Invalid expected aspect ratio. It is #{expected_aspect_ratio}.
            It should be #{VALID_ASPECT_RATIOS.join(' or ')} or something like is_4_3.
          FAILURE_MESSAGE

          false
        end
      end

      def valid_width_and_height
        case expected_aspect_ratio
        when :square
          [100, 100]
        when :portrait
          [100, 200]
        when :landscape
          [200, 100]
        else
          expected_aspect_ratio =~ /is_(\d*)_(\d*)/
          x = Regexp.last_match(1).to_i
          y = Regexp.last_match(2).to_i

          [100 * x, 100 * y]
        end
      end

      def invalid_width_and_height
        width, height = valid_width_and_height

        height = expected_aspect_ratio == :portrait ? 50 : (height * width) + 1

        [width, height]
      end

      def expected_error_message
        case expected_aspect_ratio
        when :square
          'aspect_ratio_not_square'
        when :portrait
          'aspect_ratio_not_portrait'
        when :landscape
          'aspect_ratio_not_landscape'
        else
          'aspect_ratio_is_not'
        end
      end

      def valid_when_correct_aspect_ratio
        width, height = valid_width_and_height

        @subject.public_send(attribute_name).attach attachment_for(width, height)

        attachment = @subject.public_send(attribute_name)

        ActiveStorageValidations::Matchers.mock_metadata(attachment, width, height) do
          @subject.validate

          if @subject.errors.details[attribute_name].all? do |error|
              error[:error].to_s.exclude?(expected_error_message)
            end

            true
          else
            @failure_message = <<~FAILURE_MESSAGE
              Should be valid attaching an image with aspect \
              ratio of #{expected_aspect_ratio}. But it is not.
            FAILURE_MESSAGE
            false
          end
        end
      end

      def invalid_when_incorrect_aspect_ratio
        width, height = invalid_width_and_height

        @subject.public_send(attribute_name).attach attachment_for(width, height)

        attachment = @subject.public_send(attribute_name)

        ActiveStorageValidations::Matchers.mock_metadata(attachment, width, height) do
          @subject.validate

          if @subject.errors.details[attribute_name].any? do |error|
              error[:error].to_s.include?(expected_error_message)
            end

            true
          else
            @failure_message = <<~FAILURE_MESSAGE
              Should be invalid attaching an image with aspect \
              ratio different from #{expected_aspect_ratio}. But it is not.
            FAILURE_MESSAGE
            false
          end
        end
      end

      def attachment_for(_width, _height)
        { io: Tempfile.new('Hello world!'), filename: 'test.png', content_type: 'image/png' }
      end
    end
  end
end
