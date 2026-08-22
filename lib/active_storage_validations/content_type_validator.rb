# frozen_string_literal: true

require_relative "shared/asv_active_storageable"
require_relative "shared/asv_analyzable"
require_relative "shared/asv_attachable"
require_relative "shared/asv_errorable"
require_relative "shared/asv_optionable"
require_relative "shared/asv_symbolizable"

module ActiveStorageValidations
  class ContentTypeValidator < ActiveModel::EachValidator # :nodoc:
    include ASVActiveStorageable
    include ASVAnalyzable
    include ASVAttachable
    include ASVErrorable
    include ASVOptionable
    include ASVSymbolizable

    AVAILABLE_CHECKS = %i[with in].freeze
    AVAILABLE_SPOOFING_PROTECTION_VALUES = [ true, false, :file, :magika ].freeze
    ERROR_TYPES = %i[
      content_type_invalid
      content_type_spoofed
    ].freeze
    METADATA_KEYS = %i[content_type].freeze

    # State for a single attachable check. Active Model builds one validator per
    # class and reuses it for every record and every thread, so this must travel
    # through arguments rather than instance variables.
    Context = Struct.new(:authorized_content_types, :content_type, :filename)

    def check_validity!
      ensure_exactly_one_validator_option
      ensure_content_types_validity
      ensure_spoofing_protection_validity
    end

    def validate_each(record, attribute, _value)
      return if no_attachments?(record, attribute)

      authorized_content_types = authorized_content_types_from_options(record)
      return if authorized_content_types.empty?

      attachables_and_blobs(record, attribute).each do |attachable, blob|
        context = Context.new(authorized_content_types, blob.content_type, blob.filename.to_s)
        is_valid?(record, attribute, attachable, blob, context)
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

    # Check if the provided content_type is authorized and not spoofed against
    # the file io.
    def is_valid?(record, attribute, attachable, blob, context)
      authorized_content_type?(record, attribute, attachable, context) &&
        not_spoofing_content_type?(record, attribute, attachable, blob, context)
    end

    def authorized_content_type?(record, attribute, attachable, context)
      attachable_content_type_is_authorized = context.authorized_content_types.any? do |authorized_content_type|
        case authorized_content_type
        when String then authorized_content_type == marcel_attachable_content_type(context)
        when Regexp then authorized_content_type.match?(marcel_attachable_content_type(context).to_s)
        end
      end

      return true if attachable_content_type_is_authorized

      add_content_type_invalid_error(record, attribute, attachable, context)
    end

    def marcel_attachable_content_type(context)
      Marcel::MimeType.for(declared_type: context.content_type, name: context.filename)
    end

    def not_spoofing_content_type?(record, attribute, attachable, blob, context)
      return true unless enable_spoofing_protection?

      detected_content_type = begin
        metadata_for(blob, attachable, METADATA_KEYS)&.fetch(:content_type, nil)
      rescue ActiveStorage::FileNotFoundError
        add_attachment_missing_error(record, attribute, attachable)
        return false
      end

      if content_type_mismatch?(context.content_type, detected_content_type)
        add_content_type_spoofed_error(record, attribute, attachable, context, detected_content_type)
      else
        true
      end
    end

    def enable_spoofing_protection?
      spoofing_protection_backend.present?
    end

    # +true+ and +:file+ both select the UNIX +file+ CLI; +:magika+ selects Magika.
    def spoofing_protection_backend
      case options[:spoofing_protection]
      when true, :file then :file
      when :magika then :magika
      end
    end

    def ensure_spoofing_protection_validity
      return unless options.key?(:spoofing_protection)
      return if AVAILABLE_SPOOFING_PROTECTION_VALUES.include?(options[:spoofing_protection])

      raise ArgumentError, <<~ERROR_MESSAGE
        Unknown spoofing_protection option: #{options[:spoofing_protection].inspect}.
        Allowed values: #{AVAILABLE_SPOOFING_PROTECTION_VALUES.map(&:inspect).join(", ")}
      ERROR_MESSAGE
    end

    def content_type_mismatch?(attachable_content_type, detected_content_type)
      attachable_content_type.present? &&
        !content_types_intersect?(attachable_content_type, detected_content_type)
    end

    def content_types_intersect?(attachable_content_type, detected_content_type)
      enlarged_content_type(content_type_without_parameters(attachable_content_type)).intersect?(
        enlarged_content_type(content_type_without_parameters(detected_content_type))
      )
    end

    def enlarged_content_type(content_type)
      [ content_type, *parent_content_types(content_type) ].compact.uniq
    end

    def parent_content_types(content_type)
      Marcel::TYPE_PARENTS[content_type] || []
    end

    def add_content_type_invalid_error(record, attribute, attachable, context)
      errors_options = initialize_and_populate_error_options(options, attachable, context)
      add_error(record, attribute, ERROR_TYPES.first, **errors_options)
      false
    end

    def add_content_type_spoofed_error(record, attribute, attachable, context, detected_content_type)
      errors_options = initialize_and_populate_error_options(options, attachable, context)
      errors_options[:detected_content_type] = detected_content_type
      errors_options[:detected_human_content_type] = content_type_to_human_format(detected_content_type)
      add_error(record, attribute, ERROR_TYPES.second, **errors_options)
      false
    end

    def initialize_and_populate_error_options(options, attachable, context)
      errors_options = initialize_error_options(options, attachable)
      errors_options[:content_type] = context.content_type
      errors_options[:human_content_type] = content_type_to_human_format(context.content_type)
      errors_options[:authorized_human_content_types] = content_type_to_human_format(context.authorized_content_types)
      errors_options[:count] = context.authorized_content_types.size
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
        .join(", ")
    end

    def ensure_exactly_one_validator_option
      unless AVAILABLE_CHECKS.one? { |argument| options.key?(argument) }
        raise ArgumentError, "You must pass either :with or :in to the validator"
      end
    end

    def ensure_content_types_validity
      return true if options[:with]&.is_a?(Proc) || options[:in]&.is_a?(Proc)

      (Array(options[:with]) + Array(options[:in])).each do |content_type|
        raise ArgumentError, invalid_content_type_option_message(content_type) if invalid_option?(content_type)
      end
    end

    def invalid_content_type_option_message(content_type)
      if content_type.to_s.match?(/\//)
        <<~ERROR_MESSAGE
          You must pass valid content types to the validator
          '#{content_type}' is not found in Marcel content types (Marcel::TYPE_EXTS + Marcel::MAGIC)
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
      if content_type == "image/jpg"
        raise ArgumentError, "'image/jpg' is not a valid content type, you should use 'image/jpeg' instead"
      end

      all_available_marcel_content_types.exclude?(content_type.to_s)
    end

    def all_available_marcel_content_types
      @all_available_marcel_content_types ||= Marcel::TYPE_EXTS
        .keys
        .push(*Marcel::MAGIC.map(&:first))
        .tap(&:uniq!)
    end

    def invalid_extension?(content_type)
      Marcel::MimeType.for(extension: content_type.to_s) == "application/octet-stream"
    end
  end
end
