# frozen_string_literal: true

require_relative 'concerns/active_storageable.rb'
require_relative 'concerns/errorable.rb'
require_relative 'concerns/metadatable.rb'
require_relative 'concerns/symbolizable.rb'

module ActiveStorageValidations
  class AspectRatioValidator < ActiveModel::EachValidator # :nodoc
    include ActiveStorageable
    include Errorable
    include Metadatable
    include OptionProcUnfolding
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
      aspect_ratio_unknown
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
      flat_options = unfold_procs(record, self.options, AVAILABLE_CHECKS)
      errors_options = initialize_error_options(options, attachable)

      if metadata[:width].to_i <= 0 || metadata[:height].to_i <= 0
        errors_options[:aspect_ratio] = flat_options[:with]

        add_error(record, attribute, :image_metadata_missing, **errors_options)
        return false
      end

      case flat_options[:with]
      when :square
        return true if metadata[:width] == metadata[:height]
        errors_options[:aspect_ratio] = flat_options[:with]
        add_error(record, attribute, :aspect_ratio_not_square, **errors_options)

      when :portrait
        return true if metadata[:height] > metadata[:width]
        errors_options[:aspect_ratio] = flat_options[:with]
        add_error(record, attribute, :aspect_ratio_not_portrait, **errors_options)

      when :landscape
        return true if metadata[:width] > metadata[:height]
        errors_options[:aspect_ratio] = flat_options[:with]
        add_error(record, attribute, :aspect_ratio_not_landscape, **errors_options)

      when ASPECT_RATIO_REGEX
        flat_options[:with] =~ ASPECT_RATIO_REGEX
        x = $1.to_i
        y = $2.to_i

        return true if x > 0 && y > 0 && (x.to_f / y).round(PRECISION) == (metadata[:width].to_f / metadata[:height]).round(PRECISION)

        errors_options[:aspect_ratio] = "#{x}:#{y}"
        add_error(record, attribute, :aspect_ratio_is_not, **errors_options)
      else
        errors_options[:aspect_ratio] = flat_options[:with]
        add_error(record, attribute, :aspect_ratio_unknown, **errors_options)
        return false
      end
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
