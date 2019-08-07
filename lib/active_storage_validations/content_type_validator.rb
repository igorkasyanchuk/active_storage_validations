# frozen_string_literal: true

module ActiveStorageValidations
  class ContentTypeValidator < ActiveModel::EachValidator # :nodoc:
    def validate_each(record, attribute, _value)
      return true if !record.send(attribute).attached? || types.empty?

      files = Array.wrap(record.send(attribute))

      errors_options = { authorized_types: types_to_human_format }
      errors_options[:message] = options[:message] if options[:message].present?

      files.each do |file|
        next if is_valid?(file)

        errors_options[:content_type] = content_type(file)
        record.errors.add(attribute, :content_type_invalid, errors_options)
        break
      end
    end

    def types
      (Array.wrap(options[:with]) + Array.wrap(options[:in])).compact.map do |type|
        Mime[type] || type
      end
    end

    def types_to_human_format
      types.join(', ')
    end

    def content_type(file)
      file.blob.present? && file.blob.content_type
    end

    def is_valid?(file)
      if options[:with].is_a?(Regexp)
        options[:with].match?(content_type(file).to_s)
      else
        content_type(file).in?(types)
      end
    end
  end
end
