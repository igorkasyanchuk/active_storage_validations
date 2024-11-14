# frozen_string_literal: true

require_relative 'shared/asv_active_storageable'
require_relative 'shared/asv_attachable'
require_relative 'shared/asv_errorable'
require_relative 'shared/asv_optionable'
require_relative 'shared/asv_symbolizable'

module ActiveStorageValidations
  class AspectRatioValidator < ActiveModel::EachValidator # :nodoc
    include ASVActiveStorageable
    include ASVAttachable
    include ASVErrorable
    include ASVOptionable
    include ASVSymbolizable

    AVAILABLE_CHECKS = %i[with in].freeze
    NAMED_ASPECT_RATIOS = %i[square portrait landscape].freeze
    ASPECT_RATIO_REGEX = /is_([1-9]\d*)_([1-9]\d*)/.freeze
    PRECISION = 3
    ERROR_TYPES = %i[
      aspect_ratio_invalid
      image_metadata_missing
      aspect_ratio_not_square
      aspect_ratio_not_portrait
      aspect_ratio_not_landscape
      aspect_ratio_is_not
    ].freeze

    def check_validity!
      ensure_at_least_one_validator_option
      ensure_aspect_ratio_validity
    end

    def validate_each(record, attribute, _value)
      return if no_attachments?(record, attribute)

      validate_changed_files_from_metadata(record, attribute)
    end

    private

    def is_valid?(record, attribute, attachable, metadata)
      flat_options = set_flat_options(record)

      return if image_metadata_missing?(record, attribute, attachable, flat_options, metadata)

      aspect_ratios = aspect_ratios(flat_options).compact
      errors = aspect_ratios.map do |aspect_ratio|
        aspect_ratio_error(aspect_ratio, metadata)
      end.compact

      return true if errors.length != aspect_ratios.length

      error = aspect_ratios.length == 1 ? errors.first : :aspect_ratio_invalid

      errors_options = initialize_error_options(options, attachable)
      errors_options[:aspect_ratio] = string_aspect_ratios(flat_options)
      add_error(record, attribute, error, **errors_options)
      false
    end

    def aspect_ratio_error(aspect_ratio, metadata)
      case aspect_ratio
      when :square then validate_square_aspect_ratio(metadata)
      when :portrait then validate_portrait_aspect_ratio(metadata)
      when :landscape then validate_landscape_aspect_ratio(metadata)
      when ASPECT_RATIO_REGEX then valid_regex_aspect_ratio?(aspect_ratio, metadata)
      end
    end

    def image_metadata_missing?(record, attribute, attachable, flat_options, metadata)
      return false if metadata[:width].to_i > 0 && metadata[:height].to_i > 0

      errors_options = initialize_error_options(options, attachable)
      errors_options[:aspect_ratio] = string_aspect_ratios(flat_options)
      add_error(record, attribute, :image_metadata_missing, **errors_options)
      true
    end

    def validate_square_aspect_ratio(metadata)
      :aspect_ratio_not_square unless metadata[:width] == metadata[:height]
    end

    def validate_portrait_aspect_ratio(metadata)
      :aspect_ratio_not_portrait unless metadata[:width] < metadata[:height]
    end

    def validate_landscape_aspect_ratio(metadata)
      :aspect_ratio_not_landscape unless metadata[:width] > metadata[:height]
    end

    def valid_regex_aspect_ratio?(aspect_ratio, metadata)
      aspect_ratio =~ ASPECT_RATIO_REGEX
      x = ::Regexp.last_match(1).to_i
      y = ::Regexp.last_match(2).to_i

      unless x > 0 && y > 0 && (x.to_f / y).round(PRECISION) == (metadata[:width].to_f / metadata[:height]).round(PRECISION)
        :aspect_ratio_is_not
      end
    end

    def ensure_at_least_one_validator_option
      return if AVAILABLE_CHECKS.any? { |argument| options.key?(argument) }

      raise ArgumentError, 'You must pass either :with or :in to the validator'
    end

    def ensure_aspect_ratio_validity
      return true if options[:with]&.is_a?(Proc) || options[:in]&.is_a?(Proc)

      aspect_ratios(options).each do |aspect_ratio|
        unless NAMED_ASPECT_RATIOS.include?(aspect_ratio) || aspect_ratio =~ ASPECT_RATIO_REGEX
          raise ArgumentError, invalid_aspect_ratio_message(aspect_ratio)
        end
      end
    end

    def invalid_aspect_ratio_message(aspect_ratio)
      <<~ERROR_MESSAGE
        You must pass valid content types to the validator
        '#{aspect_ratio}' is not found in Marcel::EXTENSIONS mimes
      ERROR_MESSAGE
    end

    def aspect_ratios(flat_options)
      (Array.wrap(flat_options[:with]) + Array.wrap(flat_options[:in]))
    end

    def string_aspect_ratios(flat_options)
      aspect_ratios(flat_options).map do |aspect_ratio|
        if NAMED_ASPECT_RATIOS.include?(aspect_ratio)
          aspect_ratio
        else
          aspect_ratio =~ ASPECT_RATIO_REGEX
          x = ::Regexp.last_match(1).to_i
          y = ::Regexp.last_match(2).to_i

          "#{x}:#{y}"
        end
      end.join(', ')
    end
  end
end
