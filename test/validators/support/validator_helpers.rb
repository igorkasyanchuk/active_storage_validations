# frozen_string_literal: true

module ValidatorHelpers
  def is_expected_to_be_valid(**kwargs)
    subject && assert(subject.valid?(kwargs[:context]))
  end

  def is_expected_not_to_be_valid(**kwargs)
    subject && refute(subject.valid?(kwargs[:context]))
  end

  def is_expected_to_have_error_options(error_options, **kwargs)
    subject.valid?(kwargs[:context])

    validator_error_options =
      subject.errors.find do |error|
        error.options[:validator_type] == kwargs[:validator] || validator_sym
      end&.options

    raise Minitest::Assertion, "Expected validator error options to be present but got nil" if validator_error_options.nil?

    assert(
      error_options.all? do |key, _value|
        validator_error_options.has_key?(key) &&
          value_is_equal_or_both_are_procs?(error_options[key], validator_error_options[key])
      end,
      "Expected validator error options to include #{error_options.inspect}\nbut got #{validator_error_options.inspect}"
    )
  end

  def is_expected_to_include_error_message(message_key, **kwargs)
    subject.valid?(kwargs[:context])

    validator_error_messages =
      subject.errors.select do |error|
        error.options[:validator_type] == kwargs[:validator] || validator_sym
      end.map(&:message)

    message = kwargs[:error_options][:custom_message] || I18n.t("errors.messages.#{message_key}", **kwargs[:error_options])

    assert_includes(
      validator_error_messages,
      message,
      "Expected error messages to include '#{message.inspect}'\nbut got #{validator_error_messages.inspect}"
    )
  end

  def is_expected_to_raise_error(error_class, message)
    begin
      subject.valid?
    rescue => e
      assert_equal(e.class, error_class)
      assert(e.message.include?(message))
    else
      raise StandardError, "It should raise an error but it does not raise any"
    end
  end

  def assert_nothing_raised
    # Just a placeholder to make reading easier
    yield
  end

  def validator_class
    "ActiveStorageValidations::#{subject.class.name.sub(/::/, '').sub(/::.+/, '')}".constantize
  end

  def validator_sym
    begin
      validator_class.to_sym
    rescue NameError, "uninitialized constant ActiveStorageValidations::IntegrationValidator"
      nil # Use the :validator kwarg for this expect method since it could be any validator (e.g. integration test file)
    end
  end

  private

  def value_is_equal_or_both_are_procs?(value_1, value_2)
    # Comparing Procs is tricky, let's just ensure that both values are procs
    # for now to check equality, if necessary we will investigate a better
    # solution
    (value_1 == value_2) || 
      (value_1.is_a?(Proc) && value_2.is_a?(Proc)) ||
      (value_1.is_a?(Hash) && value_2.is_a?(Hash) && value_1.values.all?(Proc) && value_2.values.all?(Proc)) # e.g. { width: { min: -> (record) { 500 } } }
  end
end
