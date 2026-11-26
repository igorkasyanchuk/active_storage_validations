# frozen_string_literal: true

module ActiveStorageValidations
  # ActiveStorageValidations::ASVActiveStorageable
  #
  # Validator helper methods to make our code more explicit.
  module ASVActiveStorageable
    extend ActiveSupport::Concern

    # ActiveModel::EachValidator#validate evaluates `value.blank?` before it
    # checks :allow_blank, and ActiveStorage::Attached::Many#blank? runs an
    # EXISTS query: one per validator on every validation of the record, even
    # when nothing was attached. Without :allow_nil / :allow_blank that check
    # can never skip the attribute, so leave it out. With either option, keep
    # Rails' own logic (Rails 8.2 also accepts a Proc for both).
    def validate(record)
      return super if options.key?(:allow_nil) || options.key?(:allow_blank)

      attributes.each do |attribute|
        value = record.read_attribute_for_validation(attribute)
        validate_each(record, attribute, prepare_value_for_validation(value, record, attribute))
      end
    end

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
