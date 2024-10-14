module ActiveStorageValidations
  module Matchers
    module Attachable
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
          filename: 'test.png',
          content_type: 'image/png'
        }
      end

      def processable_image
        {
          io: File.open(Rails.root.join('public', 'image_1920x1080.png')),
          filename: 'image_1920x1080_file.png',
          content_type: 'image/png'
        }
      end

      def not_processable_image
        {
          io: Tempfile.new('.'),
          filename: 'processable.txt',
          content_type: 'text/plain'
        }
      end

      def io
        @io ||= Tempfile.new('Hello world!')
      end
    end
  end
end
