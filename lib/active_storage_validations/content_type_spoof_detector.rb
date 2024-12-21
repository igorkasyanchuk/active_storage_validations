# frozen_string_literal: true

require_relative 'shared/asv_analyzable'
require_relative 'shared/asv_attachable'
require_relative 'shared/asv_loggable'
require 'open3'

module ActiveStorageValidations
  class ContentTypeSpoofDetector
    class FileCommandLineToolNotInstalledError < StandardError; end

    include ASVAnalyzable
    include ASVAttachable
    include ASVLoggable

    def initialize(record, attribute, attachable)
      @record = record
      @attribute = attribute
      @attachable = attachable
    end

    def spoofed?
      if supplied_content_type_vs_open3_analizer_mismatch?
        logger.info "Content Type Spoofing detected for file '#{filename}'. The supplied content type is '#{supplied_content_type}' but the content type discovered using open3 is '#{content_type_from_analyzer}'."
        true
      else
        false
      end
    end

    private

    def filename
      @filename ||= attachable_filename(@attachable).to_s
    end

    def supplied_content_type
      @supplied_content_type ||= attachable_content_type(@attachable)
    end

    def io
      @io ||= attachable_io(@attachable)
    end

    # Return the content_type found by Open3 analysis.
    #
    # Using Open3 is a better alternative than Marcel (Marcel::MimeType.for(io))
    # for analyzing content type solely based on the file io.
    def content_type_from_analyzer
      @content_type_from_analyzer ||= open3_mime_type_for_io
    end

    def open3_mime_type_for_io
      return nil if io.bytesize == 0

      Tempfile.create do |tempfile|
        tempfile.binmode
        tempfile.write(io)
        tempfile.rewind

        command = "file -b --mime-type #{tempfile.path}"
        output, status = Open3.capture2(command)

        if status.success?
          mime_type = output.strip
          return mime_type
        else
          raise "Error determining MIME type: #{output}"
        end

      rescue Errno::ENOENT
        raise FileCommandLineToolNotInstalledError, 'file command-line tool is not installed'
      end
    end

    def supplied_content_type_vs_open3_analizer_mismatch?
      supplied_content_type.present? &&
        !supplied_content_type_intersects_content_type_from_analyzer?
    end

    def supplied_content_type_intersects_content_type_from_analyzer?
      # Ruby intersects? method is only available from 3.1
      enlarged_content_type(supplied_content_type).any? do |item|
        enlarged_content_type(content_type_from_analyzer).include?(item)
      end
    end

    def enlarged_content_type(content_type)
      [content_type, *parent_content_types(content_type)].compact.uniq
    end

    def parent_content_types(content_type)
      Marcel::TYPE_PARENTS[content_type] || []
    end
  end
end
