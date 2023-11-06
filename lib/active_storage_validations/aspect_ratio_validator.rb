# frozen_string_literal: true

require_relative 'concerns/symbolizable.rb'
require_relative 'metadata.rb'

module ActiveStorageValidations
  class AspectRatioValidator < ActiveModel::EachValidator # :nodoc
    include OptionProcUnfolding
    include ErrorHandler
    include Symbolizable

    AVAILABLE_CHECKS = %i[with].freeze
    PRECISION = 3

    def check_validity!
      unless AVAILABLE_CHECKS.any? { |argument| options.key?(argument) }
        raise ArgumentError, 'You must pass :with to the validator'
      end
    end

    if Rails.gem_version >= Gem::Version.new('6.0.0')
      def validate_each(record, attribute, _value)
        return true unless record.send(attribute).attached?

        changes = record.attachment_changes[attribute.to_s]
        return true if changes.blank?

        files = Array.wrap(changes.is_a?(ActiveStorage::Attached::Changes::CreateMany) ? changes.attachables : changes.attachable)

        files.each do |file|
          metadata = Metadata.new(file).metadata
          next if is_valid?(record, attribute, metadata)
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

          next if is_valid?(record, attribute, metadata)
          break
        end
      end
    end


    private


    def is_valid?(record, attribute, metadata)
      flat_options = unfold_procs(record, self.options, AVAILABLE_CHECKS)
      errors_options = initialize_error_options(options)

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

      else
        if flat_options[:with] =~ /is_(\d*)_(\d*)/
          x = $1.to_i
          y = $2.to_i

          return true if (x.to_f / y).round(PRECISION) == (metadata[:width].to_f / metadata[:height]).round(PRECISION)

          errors_options[:aspect_ratio] = "#{x}x#{y}"
          add_error(record, attribute, :aspect_ratio_is_not, **errors_options)
        else
          errors_options[:aspect_ratio] = flat_options[:with]
          add_error(record, attribute, :aspect_ratio_unknown, **errors_options)
        end
      end
      false
    end
  end
end
