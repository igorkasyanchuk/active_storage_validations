module ActiveStorageValidations
  module Matchers
    module Attachable
      private

      def attach_file
        @subject.public_send(@attribute_name).attach(dummy_file)
        @subject.public_send(@attribute_name)
      end

      def dummy_file
        {
          io: io,
          filename: 'test.png',
          content_type: 'image/png'
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
