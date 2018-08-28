require "active_storage_validations/railtie"

module ActiveStorageValidations

  class AttachedValidator < ActiveModel::EachValidator
    def validate_each(record, attribute, value)
      unless record.send(attribute).attached?
        record.errors.add(attribute, :blank)
      end
    end
  end

  class ContentTypeValidator < ActiveModel::EachValidator
    def validate_each(record, attribute, value)
      files = record.send(attribute)

      # puts "#{attribute} --- #{value} --- #{options[:with]} --- #{options}"

      # only attached
      return true unless files.attached?
      return true if types.empty?

      files = Array.wrap(files)

      files.each do |file|
        unless content_type_valid?(file) 
          record.errors.add(attribute, :invalid)
          return
        end
      end
    end

    def types
      Array.wrap(options[:with]) + Array.wrap(options[:in])
    end

    def content_type_valid?(file)
      file.blob.content_type.in?(types)
    end

  end

end

ActiveRecord::Base.send :include, ActiveStorageValidations
