# frozen_string_literal: true

module ActiveStorageValidations
  class DimensionValidator < ActiveModel::EachValidator # :nodoc
    AVAILABLE_CHECKS = %i[width height min max].freeze

    def initialize(options)
      require 'image_processing'

      [:width, :height].each do |length|
        if options[length] and options[length].is_a?(Hash)
          if range = options[length][:in]
            raise ArgumentError, ":in must be a Range" unless range.is_a?(Range)
            options[length][:min], options[length][:max] = range.min, range.max
          end
        end
      end
      [:min, :max].each do |dim|
        if range = options[dim]
          raise ArgumentError, ":#{dim} must be a Range (width..height)" unless range.is_a?(Range)
          options[:width] = { dim => range.first }
          options[:height] = { dim => range.last }
        end
      end
      super
    end


    def check_validity!
      return true if AVAILABLE_CHECKS.any? { |argument| options.key?(argument) }
      raise ArgumentError, 'You must pass either :width, :height, :min or :max to the validator'
    end


    def validate_each(record, attribute, _value)
      return true unless record.send(attribute).attached?

      files = Array.wrap(record.send(attribute))

      files.each do |file|
        # Analyze file first if not analyzed to get all required metadata.
        file.analyze; file.reload unless file.analyzed?

        # File has no dimension and no width and height in metadata.
        raise StandardError, 'File has no dimension and no width and height in metadata' unless (['width', 'height'] - file.metadata.keys).empty?

        next if dimension_valid?(record, attribute, file.metadata)
        break
      end
    end


    def dimension_valid?(record, attribute, file_metadata)
      valid = true

      # Validation based on checks :min and :max (:min, :max has higher priority to :width, :height).
      if options[:min] || options[:max]
        if options[:min] && (
           (options[:width][:min] && file_metadata[:width] < options[:width][:min]) ||
           (options[:height][:min] && file_metadata[:height] < options[:height][:min])
          )
          valid = record.errors.add(attribute, options[:message].presence || :"dimension_min_inclusion", width: options[:width][:min], height: options[:height][:min]).empty?
        end
        if options[:max] && (
           (options[:width][:max] && file_metadata[:width] > options[:width][:max]) ||
           (options[:height][:max] && file_metadata[:height] > options[:height][:max])
          )
          valid = record.errors.add(attribute, options[:message].presence || :"dimension_max_inclusion", width: options[:width][:max], height: options[:height][:max]).empty?
        end

      # Validation based on checks :width and :height.
      else
        [:width, :height].each do |length|
          next unless options[length]
          if options[length].is_a?(Hash)
            if options[length][:in] && (file_metadata[length] < options[length][:min] || file_metadata[length] > options[length][:max])
              valid = record.errors.add(attribute, options[:message].presence || :"dimension_#{length}_inclusion", min: options[length][:min], max: options[length][:max]).empty?
            else
              if options[length][:min] && file_metadata[length] < options[length][:min]
                valid = record.errors.add(attribute, options[:message].presence || :"dimension_#{length}_greater_than_or_equal_to", length: options[length][:min]).empty?
              end
              if options[length][:max] && file_metadata[length] > options[length][:max]
                valid = record.errors.add(attribute, options[:message].presence || :"dimension_#{length}_less_than_or_equal_to", length: options[length][:max]).empty?
              end
            end
          else
            if file_metadata[length] != options[length]
              valid = record.errors.add(attribute, options[:message].presence || :"dimension_#{length}_equal_to", length: options[length]).empty?
            end
          end
        end
      end

      valid
    end

  end
end
