# frozen_string_literal: true

module ActiveStorageValidations
  # ActiveStorageValidations::ASVAttachable
  #
  # Validator methods for analyzing attachable.
  #
  # An attachable is a file representation such as ActiveStorage::Blob,
  # ActionDispatch::Http::UploadedFile, Rack::Test::UploadedFile, Hash, String,
  # File or Pathname
  module ASVAttachable
    extend ActiveSupport::Concern

    private

    # Loop through the newly submitted attachables to validate them. Using
    # attachables is the only way to get the attached file io that is necessary
    # to perform file analyses.
    def validate_changed_files_from_metadata(record, attribute)
      attachables_from_changes(record, attribute).each do |attachable|
        is_valid?(record, attribute, attachable, metadata_for(attachable))
      end
    end

    # Retrieve an array of newly submitted attachables. Some file could be passed
    # several times, we just need to perform the analysis once on the file,
    # therefore the use of #uniq.
    def attachables_from_changes(record, attribute)
      changes = record.attachment_changes[attribute.to_s]
      return [] if changes.blank?

      Array.wrap(
        changes.is_a?(ActiveStorage::Attached::Changes::CreateMany) ? changes.attachables : changes.attachable
      ).uniq
    end

    # Retrieve the full declared content_type from attachable.
    def full_attachable_content_type(attachable)
      case attachable
      when ActiveStorage::Blob
        attachable.content_type
      when ActionDispatch::Http::UploadedFile
        attachable.content_type
      when Rack::Test::UploadedFile
        attachable.content_type
      when String
        blob = ActiveStorage::Blob.find_signed!(attachable)
        blob.content_type
      when Hash
        attachable[:content_type]
      when File
        supports_file_attachment? ? marcel_content_type_from_filename(attachable) : raise_rails_like_error(attachable)
      when Pathname
        supports_pathname_attachment? ? marcel_content_type_from_filename(attachable) : raise_rails_like_error(attachable)
      else
        raise_rails_like_error(attachable)
      end
    end

    # Retrieve the declared content_type from attachable without potential mime
    # type parameters (e.g. 'application/x-rar-compressed;version=5')
    def attachable_content_type(attachable)
      full_attachable_content_type(attachable) && full_attachable_content_type(attachable).downcase.split(/[;,\s]/, 2).first
    end
      
    # Retrieve the content_type from attachable using the same logic as Rails
    # ActiveStorage::Blob::Identifiable#identify_content_type
    def attachable_content_type_rails_like(attachable)
      Marcel::MimeType.for(
        attachable_io(attachable, max_byte_size: 4.kilobytes),
        name: attachable_filename(attachable).to_s,
        declared_type: full_attachable_content_type(attachable)
      )
    end

    # Retrieve the media type of the attachable, which is the first part of the
    # content type (or mime type).
    # Possible values are: application/audio/example/font/image/model/text/video
    def attachable_media_type(attachable)
      (full_attachable_content_type(attachable) || marcel_content_type_from_filename(attachable)).split("/").first
    end
    
    # Retrieve the io from attachable.
    def attachable_io(attachable, max_byte_size: nil)
      io = case attachable
           when ActiveStorage::Blob
             (max_byte_size && supports_blob_download_chunk?) ? attachable.download_chunk(0...max_byte_size) : attachable.download
           when ActionDispatch::Http::UploadedFile
             max_byte_size ? attachable.read(max_byte_size) : attachable.read
           when Rack::Test::UploadedFile
             max_byte_size ? attachable.read(max_byte_size) : attachable.read
           when String
             blob = ActiveStorage::Blob.find_signed!(attachable)
             (max_byte_size && supports_blob_download_chunk?) ? blob.download_chunk(0...max_byte_size) : blob.download
           when Hash
             max_byte_size ? attachable[:io].read(max_byte_size) : attachable[:io].read
           when File
             raise_rails_like_error(attachable) unless supports_file_attachment?
             max_byte_size ? attachable.read(max_byte_size) : attachable.read
           when Pathname
             raise_rails_like_error(attachable) unless supports_pathname_attachment?
             max_byte_size ? attachable.read(max_byte_size) : attachable.read
           else
             raise_rails_like_error(attachable)
           end

      rewind_attachable_io(attachable)
      io
    end

    # Rewind the io attachable.
    def rewind_attachable_io(attachable)
      case attachable
      when ActiveStorage::Blob, String
        # nothing to do
      when ActionDispatch::Http::UploadedFile, Rack::Test::UploadedFile
        attachable.rewind
      when Hash
        attachable[:io].rewind
      when File
        raise_rails_like_error(attachable) unless supports_file_attachment?
        attachable.rewind
      when Pathname
        raise_rails_like_error(attachable) unless supports_pathname_attachment?
        File.open(attachable) { |f| f.rewind }
      else
        raise_rails_like_error(attachable)
      end
    end

    # Retrieve the declared filename from attachable.
    def attachable_filename(attachable)
      case attachable
      when ActiveStorage::Blob
        attachable.filename
      when ActionDispatch::Http::UploadedFile
        attachable.original_filename
      when Rack::Test::UploadedFile
        attachable.original_filename
      when String
        blob = ActiveStorage::Blob.find_signed!(attachable)
        blob.filename
      when Hash
        attachable[:filename]
      when File
        supports_file_attachment? ? File.basename(attachable) : raise_rails_like_error(attachable)
      when Pathname
        supports_pathname_attachment? ? File.basename(attachable) : raise_rails_like_error(attachable)
      else
        raise_rails_like_error(attachable)
      end
    end

    # Raise the same Rails error for not-implemented file representations.
    def raise_rails_like_error(attachable)
      raise(
        ArgumentError,
        "Could not find or build blob: expected attachable, " \
          "got #{attachable.inspect}"
      )
    end

    # Check if the current Rails version supports File or Pathname attachment
    #
    # https://github.com/rails/rails/blob/7-1-stable/activestorage/CHANGELOG.md#rails-710rc1-september-27-2023
    def supports_file_attachment?
      Rails.gem_version >= Gem::Version.new('7.1.0.rc1')
    end
    alias :supports_pathname_attachment? :supports_file_attachment?

    # Check if the current Rails version supports ActiveStorage::Blob#download_chunk
    #
    # https://github.com/rails/rails/blob/7-0-stable/activestorage/CHANGELOG.md#rails-700alpha1-september-15-2021
    def supports_blob_download_chunk?
      Rails.gem_version >= Gem::Version.new('7.0.0.alpha1')
    end

    # Retrieve the content_type from the file name only
    def marcel_content_type_from_filename(attachable)
      Marcel::MimeType.for(name: attachable_filename(attachable).to_s)
    end
  end
end
