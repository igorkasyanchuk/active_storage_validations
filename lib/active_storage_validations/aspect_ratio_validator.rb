# frozen_string_literal: true

require_relative 'concerns/active_storageable.rb'
require_relative 'concerns/errorable.rb'
require_relative 'concerns/metadatable.rb'
require_relative 'concerns/optionable.rb'
require_relative 'concerns/symbolizable.rb'

module ActiveStorageValidations
  class AspectRatioValidator < ActiveModel::EachValidator # :nodoc
    include ActiveStorageable
    include Errorable
    include Metadatable
    include Optionable
    include Symbolizable

    AVAILABLE_CHECKS = %i[with].freeze
    NAMED_ASPECT_RATIOS = %i[square portrait landscape].freeze
    ASPECT_RATIO_REGEX = /is_([1-9]\d*)_([1-9]\d*)/.freeze
    ERROR_TYPES = %i[
      image_metadata_missing
      aspect_ratio_not_square
      aspect_ratio_not_portrait
      aspect_ratio_not_landscape
      aspect_ratio_is_not
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

      case flat_options[:with]
      when :square then validate_square_aspect_ratio(record, attribute, attachable, flat_options, metadata)
      when :portrait then validate_portrait_aspect_ratio(record, attribute, attachable, flat_options, metadata)
      when :landscape then validate_landscape_aspect_ratio(record, attribute, attachable, flat_options, metadata)
      when ASPECT_RATIO_REGEX then validate_regex_aspect_ratio(record, attribute, attachable, flat_options, metadata)
      end
    end

    def image_metadata_missing?(record, attribute, attachable, flat_options, metadata)
      return false if metadata[:width].to_i > 0 && metadata[:height].to_i > 0

      errors_options = initialize_error_options(options, attachable)
      errors_options[:aspect_ratio] = flat_options[:with]
      add_error(record, attribute, :image_metadata_missing, **errors_options)
      true
  end

    def validate_square_aspect_ratio(record, attribute, attachable, flat_options, metadata)
      return if metadata[:width] == metadata[:height]

      errors_options = initialize_error_options(options, attachable)
      errors_options[:aspect_ratio] = flat_options[:with]
      add_error(record, attribute, :aspect_ratio_not_square, **errors_options)
    end

    def validate_portrait_aspect_ratio(record, attribute, attachable, flat_options, metadata)
      return if metadata[:width] < metadata[:height]

      errors_options = initialize_error_options(options, attachable)
      errors_options[:aspect_ratio] = flat_options[:with]
      add_error(record, attribute, :aspect_ratio_not_portrait, **errors_options)
    end

    def validate_landscape_aspect_ratio(record, attribute, attachable, flat_options, metadata)
      return true if metadata[:width] > metadata[:height]

      errors_options = initialize_error_options(options, attachable)
      errors_options[:aspect_ratio] = flat_options[:with]
      add_error(record, attribute, :aspect_ratio_not_landscape, **errors_options)
    end

    def validate_regex_aspect_ratio(record, attribute, attachable, flat_options, metadata)
      flat_options[:with] =~ ASPECT_RATIO_REGEX
      x = $1.to_i
      y = $2.to_i

      return true if x > 0 && y > 0 && (x.to_f / y).round(PRECISION) == (metadata[:width].to_f / metadata[:height]).round(PRECISION)

      errors_options = initialize_error_options(options, attachable)
      errors_options[:aspect_ratio] = "#{x}:#{y}"
      add_error(record, attribute, :aspect_ratio_is_not, **errors_options)
    end

    def ensure_at_least_one_validator_option
      unless AVAILABLE_CHECKS.any? { |argument| options.key?(argument) }
        raise ArgumentError, 'You must pass :with to the validator'
      end
    end

    def ensure_aspect_ratio_validity
      return true if options[:with]&.is_a?(Proc)

      unless NAMED_ASPECT_RATIOS.include?(options[:with]) || options[:with] =~ ASPECT_RATIO_REGEX
        raise ArgumentError, <<~ERROR_MESSAGE
          You must pass a valid aspect ratio to the validator
          It should either be a named aspect ratio (#{NAMED_ASPECT_RATIOS.join(', ')})
          Or an aspect ratio like 'is_16_9' (matching /#{ASPECT_RATIO_REGEX.source}/)
        ERROR_MESSAGE
      end
    end
  end
end
