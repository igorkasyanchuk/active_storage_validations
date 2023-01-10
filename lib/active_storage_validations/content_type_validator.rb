# frozen_string_literal: true

module ActiveStorageValidations
  class ContentTypeValidator < ActiveModel::EachValidator # :nodoc:
    include OptionProcUnfolding
    include ErrorHandler

    AVAILABLE_CHECKS = %i[with in].freeze
    
    def validate_each(record, attribute, _value)
      return true unless record.send(attribute).attached?

      types = authorized_types(record)
      return true if types.empty?
      
      files = Array.wrap(record.send(attribute))

      errors_options = initialize_error_options(options)
      errors_options[:authorized_types] = types_to_human_format(types)

      files.each do |file|
        next if is_valid?(file, types)

        errors_options[:content_type] = content_type(file)
        add_error(record, attribute, :content_type_invalid, **errors_options)
        break
      end
    end

    def authorized_types(record)
      flat_options = unfold_procs(record, self.options, AVAILABLE_CHECKS)
      (Array.wrap(flat_options[:with]) + Array.wrap(flat_options[:in])).compact.map do |type|
        if type.is_a?(Regexp)
          type
        else
          Marcel::MimeType.for(declared_type: type.to_s, extension: type.to_s)
        end
      end
    end

    def types_to_human_format(types)
      types
        .map { |type| type.to_s.split('/').last.upcase }
        .join(', ')
    end

    def content_type(file)
      file.blob.present? && file.blob.content_type
    end

    def is_valid?(file, types)
      file_type = content_type(file)
      types.any? do |type|
        type == file_type || (type.is_a?(Regexp) && type.match?(file_type.to_s))
      end
    end
  end
end
