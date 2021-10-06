# frozen_string_literal: true

require_relative 'metadata.rb'

module ActiveStorageValidations
  class DimensionValidator < ActiveModel::EachValidator # :nodoc
    AVAILABLE_CHECKS = %i[width height min max].freeze

    def initialize(options)
      require 'mini_magick' unless defined?(MiniMagick)
      super
    end
    
    def resolve_proc_options(record)
      resolved_options = {}
      [:width, :height].each do |length|
        if options[length] and options[length].is_a?(Hash)
          if range = options[length][:in]
            range = range.call(record) if range.is_a?(Proc)
            raise ArgumentError, ":in must be a Range" unless range.is_a?(Range)
            resolved_options[length] = {
              in: range,
              min: range.min,
              max: range.max
            }
          end
          if (min = options[length][:min]) && min.is_a?(Proc)
            (resolved_options[length] ||= {})[:min] = min.call(record)
          end
          if (max = options[length][:max]) && max.is_a?(Proc)
            (resolved_options[length] ||= {})[:max] = max.call(record)
          end
        elsif options[length].is_a?(Proc)
          resolved_options[length] = options[length].call(record)
        end
      end
      [:min, :max].each do |dim|
        if range = options[dim]
          range = range.call(record) if range.is_a?(Proc)
          raise ArgumentError, ":#{dim} must be a Range (width..height)" unless range.is_a?(Range)
          resolved_options[dim]     = range
          resolved_options[:width]  = { dim => range.first }
          resolved_options[:height] = { dim => range.last }
        end
      end

      resolved_options
    end


    def check_validity!
      return true if AVAILABLE_CHECKS.any? { |argument| options.key?(argument) }
      raise ArgumentError, 'You must pass either :width, :height, :min or :max to the validator'
    end


    if Rails.gem_version >= Gem::Version.new('6.0.0')
      def validate_each(record, attribute, _value)
        return true unless record.send(attribute).attached?

        changes = record.attachment_changes[attribute.to_s]
        return true if changes.blank?

        options = self.options.deep_merge(resolve_proc_options(record))
        files = Array.wrap(changes.is_a?(ActiveStorage::Attached::Changes::CreateMany) ? changes.attachables : changes.attachable)
        files.each do |file|
          metadata = Metadata.new(file).metadata
          next if is_valid?(record, attribute, metadata, options)
          break
        end
      end
    else
      # Rails 5
      def validate_each(record, attribute, _value)
        return true unless record.send(attribute).attached?

        options = self.options.deep_merge(resolve_proc_options(record))
        files = Array.wrap(record.send(attribute))
        files.each do |file|
          # Analyze file first if not analyzed to get all required metadata.
          file.analyze; file.reload unless file.analyzed?
          metadata = file.metadata rescue {}
          next if is_valid?(record, attribute, metadata, options)
          break
        end
      end
    end


    def is_valid?(record, attribute, file_metadata, options)
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
      return if record.errors.added?(attribute, type)
      record.errors.add(attribute, type, **attrs)
    end

  end
end
