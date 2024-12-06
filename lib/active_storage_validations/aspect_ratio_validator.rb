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
    ERROR_TYPES = %i[
      aspect_ratio_not_square
      aspect_ratio_not_portrait
      aspect_ratio_not_landscape
      aspect_ratio_is_not
      aspect_ratio_invalid
      image_metadata_missing
    ].freeze
    PRECISION = 3.freeze

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
      errors = add_errors(aspect_ratios, metadata)

      return true if errors.length != aspect_ratios.length

      error = aspect_ratios.length == 1 ? errors.first : :aspect_ratio_invalid

      errors_options = initialize_error_options(options, attachable)
      errors_options[:aspect_ratio] = string_aspect_ratios(flat_options)
      add_error(record, attribute, error, **errors_options)
      false
    end

    def add_errors(aspect_ratios, metadata)
      aspect_ratios.map do |aspect_ratio|
        aspect_ratio_error(aspect_ratio, metadata)
      end.compact.uniq
    end

    def aspect_ratio_error(aspect_ratio, metadata)
      if aspect_ratio == :square && !valid_square_aspect_ratio?(metadata)
        :aspect_ratio_not_square
      elsif aspect_ratio == :portrait && !valid_portrait_aspect_ratio?(metadata)
        :aspect_ratio_not_portrait
      elsif aspect_ratio == :landscape && !valid_landscape_aspect_ratio?(metadata)
        :aspect_ratio_not_landscape
      elsif ASPECT_RATIO_REGEX.match?(aspect_ratio) && !valid_regex_aspect_ratio?(aspect_ratio, metadata)
        :aspect_ratio_is_not
      end
    end

    def image_metadata_missing?(record, attribute, attachable, flat_options, metadata)
      return false if metadata[:width].to_i > 0 && metadata[:height].to_i > 0

      errors_options = initialize_error_options(options, attachable)
      errors_options[:aspect_ratio] = string_aspect_ratios(flat_options)
      add_error(record, attribute, :image_metadata_missing, **errors_options)
      true
    end

    def valid_square_aspect_ratio?(metadata)
      metadata[:width] == metadata[:height]
    end

    def valid_portrait_aspect_ratio?(metadata)
      metadata[:width] < metadata[:height]
    end

    def valid_landscape_aspect_ratio?(metadata)
      metadata[:width] > metadata[:height]
    end

    def valid_regex_aspect_ratio?(aspect_ratio, metadata)
      aspect_ratio =~ ASPECT_RATIO_REGEX
      x = ::Regexp.last_match(1).to_i
      y = ::Regexp.last_match(2).to_i

      x > 0 && y > 0 && (x.to_f / y).round(PRECISION) == (metadata[:width].to_f / metadata[:height]).round(PRECISION)
    end

    def ensure_at_least_one_validator_option
      return if AVAILABLE_CHECKS.any? { |argument| options.key?(argument) }

      raise ArgumentError, 'You must pass either :with or :in to the validator'
    end

    def ensure_aspect_ratio_validity
      return true if options[:with]&.is_a?(Proc) || options[:in]&.is_a?(Proc)

      aspect_ratios(options).each do |aspect_ratio|
        unless NAMED_ASPECT_RATIOS.include?(aspect_ratio) || aspect_ratio =~ ASPECT_RATIO_REGEX
          raise ArgumentError, invalid_aspect_ratio_message
        end
      end
    end

    def invalid_aspect_ratio_message
      <<~ERROR_MESSAGE
        You must pass a valid aspect ratio to the validator
        It should either be a named aspect ratio (#{NAMED_ASPECT_RATIOS.join(', ')})
        Or an aspect ratio like 'is_16_9' (matching /#{ASPECT_RATIO_REGEX.source}/)
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
