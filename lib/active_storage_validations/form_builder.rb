# frozen_string_literal: true

module ActiveStorageValidations
  module FormBuilder
    def file_field(method, options = {})
      options = options.symbolize_keys
      infer_accept = options.delete(:infer_accept)
      infer_accept = ActiveStorageValidations.infer_file_field_accept if infer_accept.nil?

      if infer_accept && !options.key?(:accept)
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

      # A file must pass every validator, so any one of them that can be
      # expressed in accept is enough to filter the picker; the others add no
      # restriction.
      content_type_validators.filter_map { |validator| accept_types_for(validator) }.flatten.uniq
    end

    # nil when one of the validator's types cannot be expressed in accept (a
    # Proc, a narrow Regexp): listing only the others would hide files the
    # validator allows.
    def accept_types_for(validator)
      types = Array(validator.options[:with]) + Array(validator.options[:in])
      accept_types = types.map { |type| accept_type_for(type) }
      accept_types if accept_types.any? && accept_types.all?
    end

    def accept_type_for(type)
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
  end
end
