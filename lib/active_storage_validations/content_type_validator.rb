# frozen_string_literal: true

require_relative 'concerns/active_storageable.rb'
require_relative 'concerns/errorable.rb'
require_relative 'concerns/optionable.rb'
require_relative 'concerns/symbolizable.rb'
require_relative 'content_type_spoof_detector.rb'

module ActiveStorageValidations
  class ContentTypeValidator < ActiveModel::EachValidator # :nodoc:
    include ActiveStorageable
    include Errorable
    include Optionable
    include Symbolizable

    AVAILABLE_CHECKS = %i[with in].freeze
    ERROR_TYPES = %i[
      content_type_invalid
      spoofed_content_type
    ].freeze

    def check_validity!
      ensure_exactly_one_validator_option
      ensure_content_types_validity
    end

    def validate_each(record, attribute, _value)
      return if no_attachments?(record, attribute)

      types = authorized_types(record)
      return if types.empty?

      attached_files(record, attribute).each do |file|
        is_valid?(record, attribute, file, types)
      end
    end

    private

    def authorized_types(record)
      flat_options = set_flat_options(record)

      (Array.wrap(flat_options[:with]) + Array.wrap(flat_options[:in])).compact.map do |type|
        case type
        when String, Symbol then Marcel::MimeType.for(declared_type: type.to_s, extension: type.to_s)
        when Regexp then type
        end
      end
    end

    def types_to_human_format(types)
      types
        .map { |type| type.is_a?(Regexp) ? type.source : type.to_s.split('/').last.upcase }
        .join(', ')
    end

    def content_type(file)
      # We remove potential mime type parameters
      file.blob.present? && file.blob.content_type.downcase.split(/[;,\s]/, 2).first
    end

    def is_valid?(record, attribute, file, types)
      file_type_in_authorized_types?(record, attribute, file, types) &&
        not_spoofing_content_type?(record, attribute, file)
    end

    def file_type_in_authorized_types?(record, attribute, file, types)
      file_type = content_type(file)
      file_type_is_authorized = types.any? do |type|
        case type
        when String then type == file_type
        when Regexp then type.match?(file_type.to_s)
        end
      end

      if file_type_is_authorized
        true
      else
        errors_options = initialize_error_options(options, file)
        errors_options[:authorized_types] = types_to_human_format(types)
        errors_options[:content_type] = content_type(file)
        add_error(record, attribute, ERROR_TYPES.first, **errors_options)
        false
      end
    end

    def not_spoofing_content_type?(record, attribute, file)
      return true unless enable_spoofing_protection?

      if ContentTypeSpoofDetector.new(record, attribute, file).spoofed?
        errors_options = initialize_error_options(options, file)
        add_error(record, attribute, ERROR_TYPES.second, **errors_options)
        false
      else
        true
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
        '#{content_type}' is not found in Marcel::EXTENSIONS mimes
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

    def enable_spoofing_protection?
      options[:spoofing_protection] == true
    end
  end
end
