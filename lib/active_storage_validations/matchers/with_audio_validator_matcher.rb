# frozen_string_literal: true

require_relative "shared/asv_active_storageable"
require_relative "shared/asv_allow_blankable"
require_relative "shared/asv_attachable"
require_relative "shared/asv_contextable"
require_relative "shared/asv_except_onable"
require_relative "shared/asv_messageable"
require_relative "shared/asv_rspecable"
require_relative "shared/asv_timeoutable"
require_relative "shared/asv_validatable"

module ActiveStorageValidations
  module Matchers
    def validate_with_audio_of(attribute_name)
      WithAudioValidatorMatcher.new(attribute_name)
    end

    class WithAudioValidatorMatcher
      include ASVActiveStorageable
      include ASVAllowBlankable
      include ASVAttachable
      include ASVContextable
      include ASVExceptOnable
      include ASVMessageable
      include ASVRspecable
      include ASVTimeoutable
      include ASVValidatable

      def initialize(attribute_name)
        initialize_allow_blankable
        initialize_contextable
        initialize_except_onable
        initialize_messageable
        initialize_rspecable
        initialize_timeoutable
        @attribute_name = attribute_name
        @expected_audio = true
      end

      def description
        "validate that :#{@attribute_name} #{audio_expectation}"
      end

      def failure_message
        "is expected to validate that :#{@attribute_name} #{audio_expectation}"
      end

      def without_audio
        @expected_audio = false
        self
      end

      def matches?(subject)
        @subject = subject.is_a?(Class) ? subject.new : subject

        is_a_valid_active_storage_attribute? &&
          is_context_valid? &&
          is_except_on_valid? &&
          is_allowing_blank? &&
          is_timeout_valid? &&
          is_custom_message_valid? &&
          is_valid_with_expected_audio? &&
          is_invalid_with_unexpected_audio?
      end

      private

      def audio_expectation
        @expected_audio ? "has an audio track" : "has no audio track"
      end

      def is_valid_with_expected_audio?
        validation_passes_with_audio?(@expected_audio)
      end

      def is_invalid_with_unexpected_audio?
        !validation_passes_with_audio?(!@expected_audio)
      end

      def is_custom_message_valid?
        return true unless @custom_message

        with_audio_metadata(false) do
          attach_file(video_file)
          validate
          detach_file
          has_an_error_message_which_is_custom_message?
        end
      end

      def validation_passes_with_audio?(audio)
        with_audio_metadata(audio) do
          attach_file(video_file)
          validate
          detach_file
          is_valid?
        end
      end

      def with_audio_metadata(audio, &block)
        Matchers.mock_metadata(io, { audio: audio }, &block)
      end

      def video_file
        {
          io: io,
          filename: "test.mp4",
          content_type: "video/mp4"
        }
      end
    end
  end
end
