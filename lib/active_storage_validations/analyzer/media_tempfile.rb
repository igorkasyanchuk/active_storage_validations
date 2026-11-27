# frozen_string_literal: true

require "tempfile"

module ActiveStorageValidations
  class Analyzer
    # The tempfile an attachable is copied to when it has no usable path
    # (blob, StringIO, …), created on the first #to_io only. Most uploads have
    # a path the analyzers read directly (ASVAttachableAdapter#with_path_or_copy),
    # and creating and deleting an unused file cost about 90µs per analysis.
    #
    # Writers call #to_io and work on the real File (ASVAttachableAdapter#copy_to_tempfile).
    # #delete cleans up like the block form of Tempfile.create.
    class MediaTempfile # :nodoc:
      def initialize(basename)
        @basename = basename
      end

      def to_io
        @file ||= Tempfile.create(@basename, binmode: true)
      end

      def created?
        !@file.nil?
      end

      def close
        @file&.close
      end

      def delete
        return unless @file

        @file.close unless @file.closed?
        File.unlink(@file.path)
      rescue Errno::ENOENT
        nil
      end
    end
  end
end
