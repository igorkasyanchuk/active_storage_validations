# frozen_string_literal: true

require "active_support/concern"

module ActiveStorageValidations
  module Matchers
    module ASVAttachable
      extend ActiveSupport::Concern

      private

      # Probe files go through the attribute writer: it only records a pending
      # change, while `attach` saves a persisted record. A has_many_attached
      # probe replaces the record's files, so only the probe files count.
      def attach_file(file = dummy_file)
        assign_files([ file ])
        @subject.public_send(@attribute_name)
      end

      def attach_files(count)
        assign_files(Array.new(count, dummy_file))
      end

      # Leaves the attribute empty (a pending removal for persisted files). The
      # record's own state is restored by ASVValidatable#restore_subject.
      def detach_file
        assign_files([])
      end
      alias :detach_files :detach_file

      def assign_files(files)
        value = many_attached? ? files : files.first
        @subject.public_send("#{@attribute_name}=", value)
      end

      def many_attached?
        @subject.public_send(@attribute_name).is_a?(ActiveStorage::Attached::Many)
      end

      def file_attached?
        @subject.public_send(@attribute_name).attached?
      end

      # Probe attachments are built on in-memory IOs: nothing to close or
      # unlink, and analyzers that need a path copy the IO to their own
      # tempfile (ASVAttachableAdapter::HashIo#with_media_path).
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
          io: StringIO.new,
          filename: "not_processable_image.txt",
          content_type: "text/plain"
        }
      end

      def io
        @io ||= StringIO.new
      end

      def image_data
        # Binary data for a 1x1 transparent PNG image
        "\x89PNG\r\n\x1A\n\x00\x00\x00\rIHDR\x00\x00\x00\x01\x00\x00\x00\x01\x08\x06\x00\x00\x00\x1F\x15\xC4\x89\x00\x00\x00\nIDATx\x9Cc\x00\x01\x00\x00\x05\x00\x01\r\n\x2D\xB4\x00\x00\x00\x00IEND\xAE\x42\x60\x82"
      end
    end
  end
end
