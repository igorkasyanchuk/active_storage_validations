require_relative "../metadata"

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
        is_valid?(record, attribute, attachable, Metadata.new(attachable).metadata)
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

    # Retrieve the io from attachable.
    def attachable_io(attachable)
      case attachable
      when ActiveStorage::Blob
        attachable.download
      when ActionDispatch::Http::UploadedFile
        attachable.read
      when Rack::Test::UploadedFile
        attachable.read
      when String
        blob = ActiveStorage::Blob.find_signed!(attachable)
        blob.download
      when Hash
        attachable[:io].read
      when File
        supports_file_attachment? ? attachable : raise_rails_like_error(attachable)
      when Pathname
        supports_pathname_attachment? ? attachable.read : raise_rails_like_error(attachable)
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

    # Retrieve the content_type from the file name only
    def marcel_content_type_from_filename(attachable)
      Marcel::MimeType.for(name: attachable_filename(attachable).to_s)
    end
  end
end
