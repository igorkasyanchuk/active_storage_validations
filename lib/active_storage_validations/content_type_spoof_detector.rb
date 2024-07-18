# frozen_string_literal: true

require_relative 'concerns/loggable'
require 'open3'

module ActiveStorageValidations
  class ContentTypeSpoofDetector
    include Loggable

    def initialize(record, attribute, file)
      @record = record
      @attribute = attribute
      @file = file
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
      @filename ||= @file.blob.present? && @file.blob.filename.to_s
    end

    def supplied_content_type
      # We remove potential mime type parameters
      @supplied_content_type ||= @file.blob.present? && @file.blob.content_type.downcase.split(/[;,\s]/, 2).first
    end

    def extension
      @extension ||= File.extname(filename)
    end

    def io
      @io ||= case @record.public_send(@attribute)
              when ActiveStorage::Attached::One then get_io_from_one
              when ActiveStorage::Attached::Many then get_io_from_many
              end
    end

    def get_io_from_one
      attachable = @record.attachment_changes[@attribute.to_s].attachable

      case attachable
      when ActionDispatch::Http::UploadedFile
        attachable.read
      when String
        blob = if Rails.gem_version < Gem::Version.new('6.1.0')
                ActiveStorage::Blob.find_signed(attachable)
              else
                ActiveStorage::Blob.find_signed!(attachable)
              end
        blob.download
      when ActiveStorage::Blob
        attachable.download
      when Hash
        attachable[:io].read
      end
    end

    def get_io_from_many
      attachables = @record.attachment_changes[@attribute.to_s].attachables

      if attachables.all? { |attachable| attachable.is_a?(ActionDispatch::Http::UploadedFile) }
        attachables.find do |uploaded_file|
          checksum = ActiveStorage::Blob.new.send(:compute_checksum_in_chunks, uploaded_file)
          checksum == @file.checksum
        end.read
      elsif attachables.all? { |attachable| attachable.is_a?(String) }
        # It's only possible to pass one String as attachable (not an array of String)
        blob = if Rails.gem_version < Gem::Version.new('6.1.0')
                 ActiveStorage::Blob.find_signed(attachables.first)
               else
                 ActiveStorage::Blob.find_signed!(attachables.first)
               end
        blob.download
      elsif attachables.all? { |attachable| attachable.is_a?(ActiveStorage::Blob) }
        attachables.find { |blob| blob == @file.blob }.download
      elsif attachables.all? { |attachable| attachable.is_a?(Hash) }
        # It's only possible to pass one Hash as attachable (not an array of Hash)
        attachables.first[:io].read
      end
    end

    def content_type_from_analyzer
      # Using Open3 is a better alternative than Marcel (Marcel::MimeType.for(io))
      # for analyzing content type solely based on the file io
      @content_type_from_analyzer ||= open3_mime_type_for_io
    end

    def open3_mime_type_for_io
      return nil if io.blank?

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
        raise StandardError, 'file command-line tool is not installed'
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
      if Rails.gem_version < Gem::Version.new('6.1.4')
        []
      else
        # Marcel parent feature is only available starting from marcel v1.0.3
        # Rails >= 6.1.4 relies on marcel ~> 1.0
        # Rails < 6.1.4 relies on marcel ~> 0.3.1
        Marcel::TYPE_PARENTS[content_type] || []
      end
    end
  end
end
