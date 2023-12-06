# frozen_string_literal: true

require_relative 'concerns/errorable.rb'
require_relative 'concerns/symbolizable.rb'
require_relative 'metadata.rb'

module ActiveStorageValidations
  class AspectRatioValidator < ActiveModel::EachValidator # :nodoc
    include OptionProcUnfolding
    include Errorable
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

    if Rails.gem_version >= Gem::Version.new('6.0.0')
      def validate_each(record, attribute, _value)
        return true unless record.send(attribute).attached?

        changes = record.attachment_changes[attribute.to_s]
        return true if changes.blank?

        files = Array.wrap(changes.is_a?(ActiveStorage::Attached::Changes::CreateMany) ? changes.attachables : changes.attachable)

        files.each do |file|
          metadata = Metadata.new(file).metadata
          next if is_valid?(record, attribute, file, metadata)
          break
        end
      end
    else
      # Rails 5
      def validate_each(record, attribute, _value)
        return true unless record.send(attribute).attached?

        files = Array.wrap(record.send(attribute))

        files.each do |file|
          # Analyze file first if not analyzed to get all required metadata.
          file.analyze; file.reload unless file.analyzed?
          metadata = file.metadata

          next if is_valid?(record, attribute, file, metadata)
          break
        end
      end
    end

    private

    def is_valid?(record, attribute, file, metadata)
      flat_options = unfold_procs(record, self.options, AVAILABLE_CHECKS)
      errors_options = initialize_error_options(options, file)

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
