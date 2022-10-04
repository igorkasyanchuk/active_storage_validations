# frozen_string_literal: true

require_relative 'metadata.rb'

module ActiveStorageValidations
  class DimensionValidator < ActiveModel::EachValidator # :nodoc
    include OptionProcUnfolding

    AVAILABLE_CHECKS = %i[width height min max].freeze

    def process_options(record)
      flat_options = unfold_procs(record, self.options, AVAILABLE_CHECKS)

      [:width, :height].each do |length|
        if flat_options[length] and flat_options[length].is_a?(Hash)
          if (range = flat_options[length][:in])
            raise ArgumentError, ":in must be a Range" unless range.is_a?(Range)
            flat_options[length][:min], flat_options[length][:max] = range.min, range.max
          end
        end
      end
      [:min, :max].each do |dim|
        if (range = flat_options[dim])
          raise ArgumentError, ":#{dim} must be a Range (width..height)" unless range.is_a?(Range)
          flat_options[:width] = { dim => range.first }
          flat_options[:height] = { dim => range.last }
        end
      end

      flat_options
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
      flat_options = process_options(record)
      # Validation fails unless file metadata contains valid width and height.
      if file_metadata[:width].to_i <= 0 || file_metadata[:height].to_i <= 0
        add_error(record, attribute, :image_metadata_missing)
        return false
      end

      # Validation based on checks :min and :max (:min, :max has higher priority to :width, :height).
      if flat_options[:min] || flat_options[:max]
        if flat_options[:min] && (
          (flat_options[:width][:min] && file_metadata[:width] < flat_options[:width][:min]) ||
          (flat_options[:height][:min] && file_metadata[:height] < flat_options[:height][:min])
          )
          add_error(record, attribute, :dimension_min_inclusion, width: flat_options[:width][:min], height: flat_options[:height][:min])
          return false
        end
        if flat_options[:max] && (
          (flat_options[:width][:max] && file_metadata[:width] > flat_options[:width][:max]) ||
          (flat_options[:height][:max] && file_metadata[:height] > flat_options[:height][:max])
          )
          add_error(record, attribute, :dimension_max_inclusion, width: flat_options[:width][:max], height: flat_options[:height][:max])
          return false
        end

      # Validation based on checks :width and :height.
      else
        width_or_height_invalid = false
        [:width, :height].each do |length|
          next unless flat_options[length]
          if flat_options[length].is_a?(Hash)
            if flat_options[length][:in] && (file_metadata[length] < flat_options[length][:min] || file_metadata[length] > flat_options[length][:max])
              add_error(record, attribute, :"dimension_#{length}_inclusion", min: flat_options[length][:min], max: flat_options[length][:max])
              width_or_height_invalid = true
            else
              if flat_options[length][:min] && file_metadata[length] < flat_options[length][:min]
                add_error(record, attribute, :"dimension_#{length}_greater_than_or_equal_to", length: flat_options[length][:min])
                width_or_height_invalid = true
              end
              if flat_options[length][:max] && file_metadata[length] > flat_options[length][:max]
                add_error(record, attribute, :"dimension_#{length}_less_than_or_equal_to", length: flat_options[length][:max])
                width_or_height_invalid = true
              end
            end
          else
            if file_metadata[length] != flat_options[length]
              add_error(record, attribute, :"dimension_#{length}_equal_to", length: flat_options[length])
              width_or_height_invalid = true
            end
          end
        end

        return false if width_or_height_invalid
      end

      true # valid file
    end

    def add_error(record, attribute, default_message, **attrs)
      message = options[:message].presence || default_message
      return if record.errors.added?(attribute, message)
      record.errors.add(attribute, message, **attrs)
    end

  end
end
