module ActiveStorageValidations
  module Matchers
    module Attachable
      private

      def attach_file(file = dummy_file)
        @subject.public_send(@attribute_name).attach(file)
        @subject.public_send(@attribute_name)
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

      def detach_file
        @subject.attachment_changes.delete(@attribute_name.to_s)
      end

      def file_attached?
        @subject.public_send(@attribute_name).attached?
      end
    end
  end
end
