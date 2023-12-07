# frozen_string_literal: true

require_relative 'concerns/errorable.rb'
require_relative 'concerns/symbolizable.rb'

module ActiveStorageValidations
  class ContentTypeValidator < ActiveModel::EachValidator # :nodoc:
    include OptionProcUnfolding
    include Errorable
    include Symbolizable

    AVAILABLE_CHECKS = %i[with in].freeze
    ERROR_TYPES = %i[content_type_invalid].freeze

    def check_validity!
      ensure_exactly_one_validator_option
      ensure_content_types_validity
    end

    def validate_each(record, attribute, _value)
      return true unless record.send(attribute).attached?

      types = authorized_types(record)
      return true if types.empty?

      files = Array.wrap(record.send(attribute))

      files.each do |file|
        next if is_valid?(file, types)

        errors_options = initialize_error_options(options, file)
        errors_options[:authorized_types] = types_to_human_format(types)
        errors_options[:content_type] = content_type(file)
        add_error(record, attribute, ERROR_TYPES.first, **errors_options)
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
        .map { |type| type.is_a?(Regexp) ? type.source : type.to_s.split('/').last.upcase }
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

    def ensure_exactly_one_validator_option
      unless AVAILABLE_CHECKS.one? { |argument| options.key?(argument) }
        raise ArgumentError, 'You must pass either :with or :in to the validator'
      end
    end

    def ensure_content_types_validity
      return true if options[:with]&.is_a?(Proc) || options[:in]&.is_a?(Proc)

      ([options[:with]] || options[:in]).each do |content_type|
        raise ArgumentError, invalid_content_type_message(content_type) if invalid_content_type?(content_type)
      end
    end

    def invalid_content_type_message(content_type)
      <<~ERROR_MESSAGE
        You must pass valid content types to the validator
        '#{content_type}' is not find in Marcel::EXTENSIONS mimes
      ERROR_MESSAGE
    end

    def invalid_content_type?(content_type)
      case content_type
      when String, Symbol
        Marcel::MimeType.for(declared_type: content_type.to_s, extension: content_type.to_s) == 'application/octet-stream'
      when Regexp
        false # We always validate regexes
      end
    end
  end
end
