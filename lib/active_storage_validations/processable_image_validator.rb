# frozen_string_literal: true

require_relative 'metadata.rb'

module ActiveStorageValidations
  class ProcessableImageValidator < ActiveModel::EachValidator # :nodoc
    include OptionProcUnfolding
    include ErrorHandler

    if Rails.gem_version >= Gem::Version.new('6.0.0')
      def validate_each(record, attribute, _value)
        return true unless record.send(attribute).attached?

        errors_options = initialize_error_options(options)

        changes = record.attachment_changes[attribute.to_s]
        return true if changes.blank?

        files = Array.wrap(changes.is_a?(ActiveStorage::Attached::Changes::CreateMany) ? changes.attachables : changes.attachable)

        files.each do |file|
          add_error(record, attribute, :image_not_processable, **errors_options) unless Metadata.new(file).valid?
        end
      end
    else
      # Rails 5
      def validate_each(record, attribute, _value)
        return true unless record.send(attribute).attached?

        files = Array.wrap(record.send(attribute))

        files.each do |file|
          add_error(record, attribute, :image_not_processable, **errors_options) unless Metadata.new(file).valid?
        end
      end
    end
  end
end
