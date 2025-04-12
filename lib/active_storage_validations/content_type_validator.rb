# frozen_string_literal: true

require_relative "shared/asv_active_storageable"
require_relative "shared/asv_analyzable"
require_relative "shared/asv_attachable"
require_relative "shared/asv_errorable"
require_relative "shared/asv_optionable"
require_relative "shared/asv_symbolizable"
require_relative "analyzer/content_type_analyzer"

module ActiveStorageValidations
  class ContentTypeValidator < ActiveModel::EachValidator # :nodoc:
    include ASVActiveStorageable
    include ASVAnalyzable
    include ASVAttachable
    include ASVErrorable
    include ASVOptionable
    include ASVSymbolizable

    AVAILABLE_CHECKS = %i[with in].freeze
    ERROR_TYPES = %i[
      content_type_invalid
      content_type_spoofed
    ].freeze
    METADATA_KEYS = %i[content_type].freeze

    def check_validity!
      ensure_exactly_one_validator_option
      ensure_content_types_validity
    end

    def validate_each(record, attribute, _value)
      return if no_attachments?(record, attribute)

      @authorized_content_types = authorized_content_types_from_options(record)
      return if @authorized_content_types.empty?

      attachables_and_blobs(record, attribute).each do |attachable, blob|
        set_attachable_cached_values(blob)
        is_valid?(record, attribute, attachable, blob)
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

    def set_attachable_cached_values(blob)
      @attachable_content_type = blob.content_type
      @attachable_filename = blob.filename.to_s
    end

    # Check if the provided content_type is authorized and not spoofed against
    # the file io.
    def is_valid?(record, attribute, attachable, blob)
      authorized_content_type?(record, attribute, attachable) &&
        not_spoofing_content_type?(record, attribute, attachable, blob)
    end

    # Dead code that we keep here for some time, maybe we will find a solution
    # to this check later? (November 2024)
    #
    # We do not perform any validations against the extension because it is an
    # unreliable source of truth. For example, a `.csv` file could have its
    # `text/csv` content_type changed to  `application/vnd.ms-excel` because
    # it had been opened by Excel at some point, making the file extension vs
    # file content_type check invalid.
    # def extension_matches_content_type?(record, attribute, attachable)
    #   return true if !@attachable_filename || !@attachable_content_type

    #   extension = @attachable_filename.split('.').last
    #   possible_extensions = Marcel::TYPE_EXTS[@attachable_content_type]
    #   return true if possible_extensions && extension.downcase.in?(possible_extensions)

    #   errors_options = initialize_and_populate_error_options(options, attachable)
    #   add_error(record, attribute, ERROR_TYPES.first, **errors_options)
    #   false
    # end

    def authorized_content_type?(record, attribute, attachable)
      attachable_content_type_is_authorized = @authorized_content_types.any? do |authorized_content_type|
        case authorized_content_type
        when String then authorized_content_type == marcel_attachable_content_type(attachable)
        when Regexp then authorized_content_type.match?(marcel_attachable_content_type(attachable).to_s)
        end
      end

      return true if attachable_content_type_is_authorized

      add_content_type_invalid_error(record, attribute, attachable)
    end

    def marcel_attachable_content_type(attachable)
      Marcel::MimeType.for(declared_type: @attachable_content_type, name: @attachable_filename)
    end

    def not_spoofing_content_type?(record, attribute, attachable, blob)
      return true unless enable_spoofing_protection?

      @detected_content_type = begin
        metadata_for(blob, attachable, METADATA_KEYS)&.fetch(:content_type, nil)
      rescue ActiveStorage::FileNotFoundError
        add_attachment_missing_error(record, attribute, attachable)
        return false
      end

      if attachable_content_type_vs_detected_content_type_mismatch?
        add_content_type_spoofed_error(record, attribute, attachable, @detected_content_type)
      else
        true
      end
    end

    def disable_spoofing_protection?
      !enable_spoofing_protection?
    end

    def enable_spoofing_protection?
      options[:spoofing_protection] == true
    end

    def attachable_content_type_vs_detected_content_type_mismatch?
      @attachable_content_type.present? &&
        !attachable_content_type_intersects_detected_content_type?
    end

    def attachable_content_type_intersects_detected_content_type?
      # Ruby intersects? method is only available from 3.1
      enlarged_content_type(content_type_without_parameters(@attachable_content_type)).any? do |item|
        enlarged_content_type(content_type_without_parameters(@detected_content_type)).include?(item)
      end
    end

    def enlarged_content_type(content_type)
      [ content_type, *parent_content_types(content_type) ].compact.uniq
    end

    def parent_content_types(content_type)
      Marcel::TYPE_PARENTS[content_type] || []
    end

    def add_content_type_invalid_error(record, attribute, attachable)
      errors_options = initialize_and_populate_error_options(options, attachable)
      add_error(record, attribute, ERROR_TYPES.first, **errors_options)
      false
    end

    def add_content_type_spoofed_error(record, attribute, attachable, detected_content_type)
      errors_options = initialize_and_populate_error_options(options, attachable)
      errors_options[:detected_content_type] = @detected_content_type
      errors_options[:detected_human_content_type] = content_type_to_human_format(@detected_content_type)
      add_error(record, attribute, ERROR_TYPES.second, **errors_options)
      false
    end

    def initialize_and_populate_error_options(options, attachable)
      errors_options = initialize_error_options(options, attachable)
      errors_options[:content_type] = @attachable_content_type
      errors_options[:human_content_type] = content_type_to_human_format(@attachable_content_type)
      errors_options[:authorized_human_content_types] = content_type_to_human_format(@authorized_content_types)
      errors_options[:count] = @authorized_content_types.size
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
