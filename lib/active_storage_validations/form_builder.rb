# frozen_string_literal: true

module ActiveStorageValidations
  module FormBuilder
    def file_field(method, options = {})
      if options[:accept].blank?
        accept = inferred_accept_types(method)
        options[:accept] = accept.join(",") if accept.any?
      end

      super(method, options)
    end

    private

    def inferred_accept_types(method)
      return [] unless @object.class.respond_to?(:validators_on)

      content_type_validators = @object.class.validators_on(method).select do |v|
        v.is_a?(ActiveStorageValidations::ContentTypeValidator)
      end

      content_type_validators.flat_map do |validator|
        types = Array(validator.options[:with]) + Array(validator.options[:in])
        types.filter_map do |type|
          case type
          when String
            type.include?("/") ? type : Marcel::MimeType.for(declared_type: type, extension: type)
          when Symbol
            Marcel::MimeType.for(declared_type: type.to_s, extension: type.to_s)
          when Regexp
            match = type.source.match(%r{\A\\A([a-z]+)/\.\*\\z\z})
            "#{match[1]}/*" if match
          end
        end
      end.uniq
    end
  end
end
