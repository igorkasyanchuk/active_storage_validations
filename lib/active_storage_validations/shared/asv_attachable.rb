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
    def validate_changed_files_from_metadata(record, attribute, metadata_keys)
      attachables_and_blobs(record, attribute).each do |attachable, blob|
        metadata = begin
          metadata_for(blob, attachable, metadata_keys)
        rescue ActiveStorage::FileNotFoundError
          add_attachment_missing_error(record, attribute, attachable)
          next
        end

        is_valid?(record, attribute, attachable, metadata)
      end
    end

    # Retrieve an array-like of attachables and blobs. Unlike its name suggests,
    # getting attachables from attachment_changes is not getting the changed
    # attachables but all attachables from the `has_many_attached` relation.
    # For the `has_one_attached` relation, it only yields the new attachable,
    # but if we are validating previously attached file, we need to use the blob
    # See #attach at: https://github.com/rails/rails/blob/main/activestorage/lib/active_storage/attached/many.rb
    #
    # Some file could be passed several times, we just need to perform the
    # analysis once on the file, therefore the use of #uniq.
    def attachables_and_blobs(record, attribute)
      changes = changes_for(record, attribute)

      return to_enum(:attachables_and_blobs, record, attribute) if changes.blank? || !block_given?

      if changes.is_a?(ActiveStorage::Attached::Changes::CreateMany)
        changes.attachables.uniq.zip(changes.blobs.uniq).each do |attachable, blob|
          yield attachable, blob
        end
      else
        yield changes.is_a?(ActiveStorage::Attached::Changes::CreateOne) ? changes.attachable : changes.blob, changes.blob
      end
    end

    def changes_for(record, attribute)
      if record.public_send(attribute).is_a?(ActiveStorage::Attached::One)
        record.attachment_changes[attribute.to_s].presence || record.public_send(attribute)
      else
        record.attachment_changes[attribute.to_s]
      end
    end

    # Retrieve the full declared content_type from attachable.
    # rubocop:disable Metrics/MethodLength
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
    # rubocop:enable Metrics/MethodLength

    # Retrieve the declared content_type from attachable without potential mime
    # type parameters (e.g. 'application/x-rar-compressed;version=5')
    def attachable_content_type(attachable)
      (full_attachable_content_type(attachable) && content_type_without_parameters(full_attachable_content_type(attachable)) || marcel_content_type_from_filename(attachable))
    end

    # Remove the potential mime type parameters from the content_type (e.g.
    # 'application/x-rar-compressed;version=5')
    def content_type_without_parameters(content_type)
      content_type && content_type.downcase.split(/[;,\s]/, 2).first
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
    # rubocop:disable Metrics/MethodLength
    # rubocop:disable Metrics/AbcSize
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
    # rubocop:enable Metrics/MethodLength
    # rubocop:enable Metrics/AbcSize

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
    # rubocop:disable Metrics/MethodLength
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
    # rubocop:enable Metrics/MethodLength

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
      Rails.gem_version >= Gem::Version.new("7.1.0.rc1")
    end
    alias :supports_pathname_attachment? :supports_file_attachment?

    # Check if the current Rails version supports ActiveStorage::Blob#download_chunk
    #
    # https://github.com/rails/rails/blob/7-0-stable/activestorage/CHANGELOG.md#rails-700alpha1-september-15-2021
    def supports_blob_download_chunk?
      Rails.gem_version >= Gem::Version.new("7.0.0.alpha1")
    end

    # Retrieve the content_type from the file name only
    def marcel_content_type_from_filename(attachable)
      Marcel::MimeType.for(name: attachable_filename(attachable).to_s)
    end

    # Add a media metadata missing error when metadata is missing.
    def add_media_metadata_missing_error(record, attribute, attachable, already_set_errors_options = nil)
      errors_options = already_set_errors_options || initialize_error_options(options, attachable)
      add_error(record, attribute, :media_metadata_missing, **errors_options)
    end

    # Add an attachment missing error when an ActiveStorage::FileNotFoundError
    # is raised.
    def add_attachment_missing_error(record, attribute, attachable)
      errors_options = initialize_error_options(options, attachable)
      add_error(record, attribute, :attachment_missing, **errors_options)
    end
  end
end
