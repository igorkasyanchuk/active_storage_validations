# frozen_string_literal: true

module ActiveStorageValidations
  module ASVErrorable
    extend ActiveSupport::Concern

    def initialize_error_options(options, file = nil)
      not_explicitly_written_options = %i[with in]
      curated_options = options.except(*not_explicitly_written_options)

      active_storage_validations_options = {
        validator_type: self.class.to_sym,
        custom_message: (options[:message] if options[:message].present?),
        filename: (get_filename(file) unless self.class.to_sym == :total_size)
      }.compact

      curated_options.merge(active_storage_validations_options)
    end

    def add_error(record, attribute, error_type, **errors_options)
      return if record.errors.added?(attribute, error_type)

      # You can read https://api.rubyonrails.org/classes/ActiveModel/Errors.html#method-i-add
      # to better understand how Rails model errors work
      record.errors.add(attribute, error_type, **errors_options)
    end

    private

    def get_filename(file)
      return nil unless file

      filename_from(file)&.to_s.presence
    end

    def filename_from(file)
      case file
      when ActiveStorage::Attached, ActiveStorage::Attachment then file.blob&.filename
      when ActiveStorage::Blob then file.filename
      when ActionDispatch::Http::UploadedFile, Rack::Test::UploadedFile then file.original_filename
      when String then ActiveStorage::Blob.find_signed!(file)&.filename
      when Hash then file[:filename]
      when File then File.basename(file)
      when Pathname then File.basename(file)
      end
    end
  end
end
