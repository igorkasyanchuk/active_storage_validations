# frozen_string_literal: true

require_relative 'metadata.rb'

module ActiveStorageValidations
  class DimensionValidator < ActiveModel::EachValidator # :nodoc
    AVAILABLE_CHECKS = %i[width height min max].freeze

    def initialize(options)
      require 'mini_magick' unless defined?(MiniMagick)

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


    if Rails::VERSION::MAJOR >= 6
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
          metadata = file.metadata rescue {}
          next if is_valid?(record, attribute, metadata)
          break
        end
      end
    end


    def is_valid?(record, attribute, file_metadata)
      # Validation fails unless file metadata contains valid width and height.
      if file_metadata[:width].to_i <= 0 || file_metadata[:height].to_i <= 0
        add_error(record, attribute, options[:message].presence || :image_metadata_missing)
        return false
      end

      # Validation based on checks :min and :max (:min, :max has higher priority to :width, :height).
      if options[:min] || options[:max]
        if options[:min] && (
          (options[:width][:min] && file_metadata[:width] < options[:width][:min]) ||
          (options[:height][:min] && file_metadata[:height] < options[:height][:min])
          )
          add_error(record, attribute, options[:message].presence || :"dimension_min_inclusion", width: options[:width][:min], height: options[:height][:min])
          return false
        end
        if options[:max] && (
          (options[:width][:max] && file_metadata[:width] > options[:width][:max]) ||
          (options[:height][:max] && file_metadata[:height] > options[:height][:max])
          )
          add_error(record, attribute, options[:message].presence || :"dimension_max_inclusion", width: options[:width][:max], height: options[:height][:max])
          return false
        end

      # Validation based on checks :width and :height.
      else
        [:width, :height].each do |length|
          next unless options[length]
          if options[length].is_a?(Hash)
            if options[length][:in] && (file_metadata[length] < options[length][:min] || file_metadata[length] > options[length][:max])
              add_error(record, attribute, options[:message].presence || :"dimension_#{length}_inclusion", min: options[length][:min], max: options[length][:max])
              return false
            else
              if options[length][:min] && file_metadata[length] < options[length][:min]
                add_error(record, attribute, options[:message].presence || :"dimension_#{length}_greater_than_or_equal_to", length: options[length][:min])
                return false
              end
              if options[length][:max] && file_metadata[length] > options[length][:max]
                add_error(record, attribute, options[:message].presence || :"dimension_#{length}_less_than_or_equal_to", length: options[length][:max])
                return false
              end
            end
          else
            if file_metadata[length] != options[length]
              add_error(record, attribute, options[:message].presence || :"dimension_#{length}_equal_to", length: options[length])
              return false
            end
          end
        end
      end

      true # valid file
    end

    def add_error(record, attribute, type, **attrs)
      key = options[:message].presence || type
      return if record.errors.added?(attribute, key)
      record.errors.add(attribute, key, **attrs)
    end

  end
end
