# frozen_string_literal: true

require_relative "shared/asv_active_storageable"
require_relative "shared/asv_analyzable"
require_relative "shared/asv_attachable"
require_relative "shared/asv_errorable"
require_relative "shared/asv_optionable"
require_relative "shared/asv_symbolizable"

module ActiveStorageValidations
  class AspectRatioValidator < ActiveModel::EachValidator # :nodoc
    include ASVActiveStorageable
    include ASVAnalyzable
    include ASVAttachable
    include ASVErrorable
    include ASVOptionable
    include ASVSymbolizable

    AVAILABLE_CHECKS = %i[with in].freeze
    NAMED_ASPECT_RATIOS = %i[square portrait landscape].freeze
    ASPECT_RATIO_REGEX = /\Ais_([1-9]\d*)_([1-9]\d*)\z/
    ERROR_TYPES = %i[
      aspect_ratio_not_square
      aspect_ratio_not_portrait
      aspect_ratio_not_landscape
      aspect_ratio_not_x_y
      aspect_ratio_invalid
      media_metadata_missing
    ].freeze
    METADATA_KEYS = %i[width height].freeze
    RATIO_PRECISION = 3

    def check_validity!
      ensure_at_least_one_validator_option
      ensure_aspect_ratio_validity
    end

    def validate_each(record, attribute, _value)
      return if no_attachments?(record, attribute)

      validate_changed_files_from_metadata(record, attribute, METADATA_KEYS)
    end

    private

    # Recomputed for every attachable rather than memoized on the validator:
    # Active Model reuses one validator instance across records and threads, so
    # per-validation state cannot live in an instance variable.
    def authorized_aspect_ratios(record)
      # A Proc nested in the list may return an Array of its own.
      aspect_ratios = authorized_aspect_ratios_from_options(set_flat_options(record)).flatten.compact

      # Procs escape check_validity!; an unknown value they return (`:sqaure`,
      # "16:9") would otherwise reject every file with "must be 0:0".
      ensure_aspect_ratios_validity(aspect_ratios) if proc_aspect_ratios?
      aspect_ratios
    end

    def is_valid?(record, attribute, attachable, metadata)
      media_metadata_present?(record, attribute, attachable, metadata) &&
        authorized_aspect_ratio?(record, attribute, attachable, metadata)
    end

    def authorized_aspect_ratio?(record, attribute, attachable, metadata)
      aspect_ratios = authorized_aspect_ratios(record)
      attachable_aspect_ratio_is_authorized = aspect_ratios.any? do |authorized_aspect_ratio|
        case authorized_aspect_ratio
        when :square then valid_square_aspect_ratio?(metadata)
        when :portrait then valid_portrait_aspect_ratio?(metadata)
        when :landscape then valid_landscape_aspect_ratio?(metadata)
        when ASPECT_RATIO_REGEX then valid_regex_aspect_ratio?(authorized_aspect_ratio, metadata)
        end
      end

      return true if attachable_aspect_ratio_is_authorized

      errors_options = initialize_and_populate_error_options(options, attachable, aspect_ratios)
      errors_options[:width] = metadata[:width]
      errors_options[:height] = metadata[:height]
      error_type = aspect_ratio_error_mapping(aspect_ratios)
      add_error(record, attribute, error_type, **errors_options)
      false
    end

    def aspect_ratio_error_mapping(aspect_ratios)
      return :aspect_ratio_invalid if aspect_ratios.empty? || aspect_ratios.many?

      aspect_ratio = aspect_ratios.first
      NAMED_ASPECT_RATIOS.include?(aspect_ratio) ? :"aspect_ratio_not_#{aspect_ratio}" : :aspect_ratio_not_x_y
    end

    def media_metadata_present?(record, attribute, attachable, metadata)
      return true if metadata[:width].to_i > 0 && metadata[:height].to_i > 0

      add_media_metadata_missing_error(record, attribute, attachable)
      false
    end

    def initialize_and_populate_error_options(options, attachable, aspect_ratios)
      errors_options = initialize_error_options(options, attachable)
      errors_options[:authorized_aspect_ratios] = string_aspect_ratios(aspect_ratios)
      errors_options
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
      x, y = ratio_components(aspect_ratio)
      width = metadata[:width].to_i
      height = metadata[:height].to_i
      return false unless x.positive? && y.positive? && width.positive? && height.positive?

      matching_ratio?(width, height, x, y)
    end

    def ratio_components(aspect_ratio)
      aspect_ratio =~ ASPECT_RATIO_REGEX
      [ ::Regexp.last_match(1).to_i, ::Regexp.last_match(2).to_i ]
    end

    # The file matches x:y when either:
    # - both ratios are equal once rounded to RATIO_PRECISION decimals, the
    #   4.x rule, which leaves a few pixels of slack on large images
    #   (2200×1237, 4032×3025), or
    # - one side is within a pixel of the other one scaled to x:y, i.e. its
    #   floor or ceil, so common sizes such as 1366×768 (1366 × 9 / 16 =
    #   768.375) and 854×480 match 16:9.
    # Strictly under a pixel: a `<= 1` margin was far too loose on small
    # images (2×2 matched 1:2, 100×2 matched 100:1).
    def matching_ratio?(width, height, x, y)
      (width.to_f / height).round(RATIO_PRECISION) == (x.to_f / y).round(RATIO_PRECISION) ||
        (height - width * y / x.to_f).abs < 1 ||
        (width - height * x / y.to_f).abs < 1
    end

    def ensure_at_least_one_validator_option
      return if AVAILABLE_CHECKS.any? { |argument| options.key?(argument) }

      raise ArgumentError, "You must pass either :with or :in to the validator"
    end

    # Procs (top-level or nested in the list) are checked when they are
    # evaluated, see #authorized_aspect_ratios.
    def ensure_aspect_ratio_validity
      ratios = authorized_aspect_ratios_from_options(options).compact
      raise ArgumentError, "You must pass at least one aspect ratio to the validator" if ratios.empty?

      ensure_aspect_ratios_validity(ratios.grep_v(Proc))
    end

    def ensure_aspect_ratios_validity(aspect_ratios)
      aspect_ratios.each do |aspect_ratio|
        raise ArgumentError, invalid_aspect_ratio_message(aspect_ratio) unless valid_aspect_ratio?(aspect_ratio)
      end
    end

    def valid_aspect_ratio?(aspect_ratio)
      NAMED_ASPECT_RATIOS.include?(aspect_ratio) ||
        ((aspect_ratio.is_a?(Symbol) || aspect_ratio.is_a?(String)) && aspect_ratio.match?(ASPECT_RATIO_REGEX))
    end

    def proc_aspect_ratios?
      authorized_aspect_ratios_from_options(options).any?(Proc)
    end

    def invalid_aspect_ratio_message(aspect_ratio)
      <<~ERROR_MESSAGE
        You must pass a valid aspect ratio to the validator (got #{aspect_ratio.inspect})
        It should either be a named aspect ratio (#{NAMED_ASPECT_RATIOS.join(', ')})
        Or an aspect ratio like 'is_16_9' (matching /#{ASPECT_RATIO_REGEX.source}/)
      ERROR_MESSAGE
    end

    def authorized_aspect_ratios_from_options(flat_options)
      (Array.wrap(flat_options[:with]) + Array.wrap(flat_options[:in]))
    end

    def string_aspect_ratios(aspect_ratios)
      aspect_ratios.map do |aspect_ratio|
        if NAMED_ASPECT_RATIOS.include?(aspect_ratio)
          aspect_ratio
        else
          x, y = ratio_components(aspect_ratio)
          "#{x}:#{y}"
        end
      end.join(", ")
    end
  end
end
