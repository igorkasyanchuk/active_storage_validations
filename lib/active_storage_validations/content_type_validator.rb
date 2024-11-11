# frozen_string_literal: true

require_relative 'concerns/active_storageable.rb'
require_relative 'concerns/attachable.rb'
require_relative 'concerns/errorable.rb'
require_relative 'concerns/optionable.rb'
require_relative 'concerns/symbolizable.rb'
require_relative 'content_type_spoof_detector.rb'

module ActiveStorageValidations
  class ContentTypeValidator < ActiveModel::EachValidator # :nodoc:
    include ActiveStorageable
    include Attachable
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

      @authorized_content_types = authorized_content_types_from_options(record)
      return if @authorized_content_types.empty?

      attachables_from_changes(record, attribute).each do |attachable|
        set_attachable_cached_values(attachable)
        is_valid?(record, attribute, attachable)
      end
    end

    private

    def authorized_content_types_from_options(record)
      flat_options = set_flat_options(record)

      (Array.wrap(flat_options[:with]) + Array.wrap(flat_options[:in])).compact.map do |type|
        case type
        when String, Symbol then Marcel::MimeType.for(declared_type: type.to_s, extension: type.to_s)
        when Regexp then type
        end
      end
    end

    def set_attachable_cached_values(attachable)
      @attachable_content_type = attachable_content_type(attachable)
      @attachable_filename = attachable_filename(attachable).to_s
    end

    def is_valid?(record, attribute, attachable)
      extension_matches_content_type?(record, attribute, attachable) &&
        authorized_content_type?(record, attribute, attachable) &&
        not_spoofing_content_type?(record, attribute, attachable)
    end

    def extension_matches_content_type?(record, attribute, attachable)
      extension = @attachable_filename.split('.').last

      possible_extensions = Marcel::TYPE_EXTS[@attachable_content_type]
      return true if possible_extensions && extension.in?(possible_extensions)

      errors_options = initialize_and_populate_error_options(options, attachable)
      add_error(record, attribute, ERROR_TYPES.first, **errors_options)
      false
    end

    def authorized_content_type?(record, attribute, attachable)
      attachable_content_type_is_authorized = @authorized_content_types.any? do |authorized_content_type|
        case authorized_content_type
        when String then authorized_content_type == marcel_attachable_content_type(attachable)
        when Regexp then authorized_content_type.match?(marcel_attachable_content_type(attachable).to_s)
        end
      end

      return true if attachable_content_type_is_authorized

      errors_options = initialize_and_populate_error_options(options, attachable)
      add_error(record, attribute, ERROR_TYPES.first, **errors_options)
      false
    end

    def not_spoofing_content_type?(record, attribute, attachable)
      return true unless enable_spoofing_protection?

      if ContentTypeSpoofDetector.new(record, attribute, attachable).spoofed?
        errors_options = initialize_error_options(options, attachable)
        add_error(record, attribute, ERROR_TYPES.second, **errors_options)
        false
      else
        true
      end
    end

    def marcel_attachable_content_type(attachable)
      Marcel::MimeType.for(declared_type: @attachable_content_type, name: @attachable_filename)
    end

    def enable_spoofing_protection?
      options[:spoofing_protection] == true
    end

    def initialize_and_populate_error_options(options, attachable)
      errors_options = initialize_error_options(options, attachable)
      errors_options[:content_type] = @attachable_content_type
      errors_options[:human_content_type] = content_type_to_human_format(@attachable_content_type)
      errors_options[:authorized_types] = content_type_to_human_format(@authorized_content_types)
      errors_options
    end

    def content_type_to_human_format(content_type)
      Array(content_type)
        .map do |content_type|
          case content_type
          when String, Symbol
            content_type.to_s.match?(/\//) ? Marcel::TYPE_EXTS[content_type.to_s]&.first&.upcase : content_type.upcase
          when Regexp
            content_type.source
          end
        end
        .flatten
        .compact
        .join(', ')
    end

    def ensure_exactly_one_validator_option
      unless AVAILABLE_CHECKS.one? { |argument| options.key?(argument) }
        raise ArgumentError, 'You must pass either :with or :in to the validator'
      end
    end

    def ensure_content_types_validity
      return true if options[:with]&.is_a?(Proc) || options[:in]&.is_a?(Proc)

      ([options[:with]] || options[:in]).each do |content_type|
        raise ArgumentError, invalid_content_type_option_message(content_type) if invalid_option?(content_type)
      end
    end

    def invalid_content_type_option_message(content_type)
      if content_type.to_s.match?(/\//)
        <<~ERROR_MESSAGE
          You must pass valid content types to the validator
          '#{content_type}' is not found in Marcel::TYPE_EXTS
        ERROR_MESSAGE
      else
        <<~ERROR_MESSAGE
          You must pass valid content types extensions to the validator
          '#{content_type}' is not found in Marcel::EXTENSIONS
        ERROR_MESSAGE
      end
    end

    def invalid_option?(content_type)
      case content_type
      when String, Symbol
        content_type.to_s.match?(/\//) ? invalid_content_type?(content_type) : invalid_extension?(content_type)
      when Regexp
        false # We always validate regexes
      end
    end

    def invalid_content_type?(content_type)
      Marcel::TYPE_EXTS[content_type.to_s] == nil
    end

    def invalid_extension?(content_type)
      Marcel::MimeType.for(extension: content_type.to_s) == 'application/octet-stream'
    end
  end
end
