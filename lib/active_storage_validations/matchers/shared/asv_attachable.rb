# frozen_string_literal: true

require "active_support/concern"

module ActiveStorageValidations
  module Matchers
    module ASVAttachable
      extend ActiveSupport::Concern

      private

      def attach_file(file = dummy_file)
        @subject.public_send(@attribute_name).attach(file)
        @subject.public_send(@attribute_name)
      end

      def attach_files(count)
        return unless count.positive?

        file_array = Array.new(count, dummy_file)

        @subject.public_send(@attribute_name).attach(file_array)
      end

      def detach_file
        @subject.attachment_changes.delete(@attribute_name.to_s)
      end
      alias :detach_files :detach_file

      def file_attached?
        @subject.public_send(@attribute_name).attached?
      end

      def dummy_blob
        ActiveStorage::Blob.create_and_upload!(**dummy_file)
      end

      def dummy_file
        {
          io: io,
          filename: "test.png",
          content_type: "image/png"
        }
      end

      def processable_image
        {
          io: StringIO.new(image_data),
          filename: "processable_image.png",
          content_type: "image/png"
        }
      end

      def not_processable_image
        {
          io: Tempfile.new("."),
          filename: "not_processable_image.txt",
          content_type: "text/plain"
        }
      end

      def io
        @io ||= Tempfile.new("Hello world!")
      end

      def image_data
        # Binary data for a 1x1 transparent PNG image
        "\x89PNG\r\n\x1A\n\x00\x00\x00\rIHDR\x00\x00\x00\x01\x00\x00\x00\x01\x08\x06\x00\x00\x00\x1F\x15\xC4\x89\x00\x00\x00\nIDATx\x9Cc\x00\x01\x00\x00\x05\x00\x01\r\n\x2D\xB4\x00\x00\x00\x00IEND\xAE\x42\x60\x82"
      end
    end
  end
end
