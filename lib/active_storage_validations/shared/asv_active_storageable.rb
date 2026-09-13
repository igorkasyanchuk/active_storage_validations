# frozen_string_literal: true

module ActiveStorageValidations
  # ActiveStorageValidations::ASVActiveStorageable
  #
  # Validator helper methods to make our code more explicit.
  module ASVActiveStorageable
    extend ActiveSupport::Concern

    private

    # Retrieve either an `ActiveStorage::Attached::One` or an
    # `ActiveStorage::Attached::Many` instance depending on attribute definition.
    # Attachments marked for destruction are omitted so size / limit / total_size
    # match what will remain after save (AttachedValidator already special-cases this).
    def attached_files(record, attribute)
      Array.wrap(record.send(attribute)).reject { |file| file.try(:marked_for_destruction?) }
    end

    def attachments_present?(record, attribute)
      record.send(attribute).attached?
    end

    def no_attachments?(record, attribute)
      !attachments_present?(record, attribute)
    end

    def will_have_attachments_after_save?(record, attribute)
      !Array.wrap(record.send(attribute)).all?(&:marked_for_destruction?)
    end
  end
end
