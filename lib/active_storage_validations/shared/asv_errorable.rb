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

      error = record.errors.add(attribute, error_type, **errors_options)

      # Rails 8.0.2 introduced a new way to mark errors as nested
      # https://github.com/igorkasyanchuk/active_storage_validations/issues/377
      if Rails.gem_version >= Gem::Version.new("8.0.2")
        # Mark errors as nested when they occur in a parent/child context
        set_nested_error(record, error) if updating_through_parent?(record)
      end

      # You can read https://api.rubyonrails.org/classes/ActiveModel/Errors.html#method-i-add
      # to better understand how Rails model errors work
      error
    end

    private

    def get_filename(file)
      return nil unless file

      case file
      when ActiveStorage::Attached, ActiveStorage::Attachment then file.blob&.filename&.to_s
      when ActiveStorage::Blob then file.filename
      when Hash then file[:filename]
      end.to_s
    end

    def updating_through_parent?(record)
      record.instance_variable_defined?(:@marked_for_destruction) ||
        record.instance_variable_defined?(:@_destroy) ||
        (record.respond_to?(:parent) && record.parent.present?)
    end

    def set_nested_error(record, error)
      reflection = record.class.reflect_on_association(:parent)

      if reflection
        association = record.association(reflection.name)
        record.errors.objects.append(ActiveRecord::Associations::NestedError.new(association, error))
      end
    end
  end
end
