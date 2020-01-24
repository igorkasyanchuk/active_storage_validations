# frozen_string_literal: true

begin
  require 'minitest/mock'
rescue LoadError
end
begin
  require 'rspec/mocks/standalone'
rescue LoadError
end

module ActiveStorageValidations
  module Matchers
    def validate_dimensions_of(name)
      DimensionValidatorMatcher.new(name)
    end

    class DimensionValidatorMatcher
      def initialize(attribute_name)
        @attribute_name = attribute_name
        @width_min = @width_max = @height_min = @height_max = nil
      end

      def description
        "validate image dimensions of #{@attribute_name}"
      end

      def width_min(width)
        @width_min = width
        self
      end

      def width_max(width)
        @width_max = width
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

      def width_between(range)
        @width_min, @width_max = range.first, range.last
        self
      end

      def height_between(range)
        @height_min, @height_max = range.first, range.last
        self
      end

      def matches?(subject)
        @subject = subject.is_a?(Class) ? subject.new : subject
        width_smaller_than_min? && width_larger_than_min? && width_smaller_than_max? && width_larger_than_max? &&
          height_smaller_than_min? && height_larger_than_min? && height_smaller_than_max? && height_larger_than_max?
      end

      def failure_message
        <<~MESSAGE
          is expected to validate dimensions of #{@attribute_name}
            width between #{@width_min} and #{@width_max}
            height between #{@height_min} and #{@height_max}
        MESSAGE
      end

      protected

      def valid_width
        ((@width_min || 0) + (@width_max || 2000)) / 2
      end

      def valid_height
        ((@height_min || 0) + (@height_max || 2000)) / 2
      end

      def width_smaller_than_min?
        @width_min.nil? || !passes_validation_with_dimensions(@width_min - 1, valid_height, 'width')
      end

      def width_larger_than_min?
        @width_min.nil? || passes_validation_with_dimensions(@width_min + 1, valid_height, 'width')
      end

      def width_smaller_than_max?
        @width_max.nil? || passes_validation_with_dimensions(@width_max - 1, valid_height, 'width')
      end

      def width_larger_than_max?
        @width_max.nil? || !passes_validation_with_dimensions(@width_max + 1, valid_height, 'width')
      end

      def height_smaller_than_min?
        @height_min.nil? || !passes_validation_with_dimensions(valid_width, @height_min - 1, 'height')
      end

      def height_larger_than_min?
        @height_min.nil? || passes_validation_with_dimensions(valid_width, @height_min + 1, 'height')
      end

      def height_smaller_than_max?
        @height_max.nil? || passes_validation_with_dimensions(valid_width, @height_max - 1, 'height')
      end

      def height_larger_than_max?
        @height_max.nil? || !passes_validation_with_dimensions(valid_width, @height_max + 1, 'height')
      end

      def passes_validation_with_dimensions(width, height, check)
        @subject.public_send(@attribute_name).attach attachment_for(width, height)

        mock_metadata(width, height) do
          @subject.validate
          @subject.errors.details[@attribute_name].all? { |error| error[:error].to_s.exclude?("dimension_#{check}") }
        end
      end

      def mock_metadata(width, height)
        # Stub the metadata analysis for rails 5
        if Rails::VERSION::MAJOR == 5
          attachment = @subject.public_send(@attribute_name)
          override_method(attachment, :analyze) { true }
          override_method(attachment, :analyzed?) { true }
          override_method(attachment, :metadata) { { width: width, height: height } }
        end

        # Mock the Metadata class for rails 6
        mock = OpenStruct.new(metadata: { width: width, height: height })
        if defined?(Minitest::Mock)
          ActiveStorageValidations::Metadata.stub(:new, mock) do
            yield
          end
        elsif defined?(RSpec::Mocks)
          ActiveStorageValidations::Metadata.stub(:new) { mock }
          yield
        else
          raise 'Need either Minitest::Mock or RSpec::Mocks to run this validator matcher'
        end
      end

      def override_method(object, method, &replacement)
        (class << object; self; end).class_eval do
          undef_method(method) if method_defined?(method)
          define_method(method, &replacement)
        end
      end

      def attachment_for(width, height)
        { io: Tempfile.new('Hello world!'), filename: 'test.png', content_type: 'image/png' }
      end
    end
  end
end
