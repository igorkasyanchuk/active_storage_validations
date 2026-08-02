# frozen_string_literal: true

# Intentionally uses RSpec's `subject` API so shared helpers work with any named
# subject (`:model`, `:record`, …). RSpec/NamedSubject only scans examples/hooks,
# not helper methods — no RuboCop disable needed here.
module ValidatorHelpers
  def is_expected_to_be_valid(**kwargs)
    expect(subject.valid?(kwargs[:context])).to be(true)
  end

  def is_expected_not_to_be_valid(**kwargs)
    expect(subject.valid?(kwargs[:context])).to be(false)
  end

  def is_expected_to_have_error_options(error_options, **kwargs)
    subject.valid?(kwargs[:context])

    validator_error_options =
      subject.errors.find do |error|
        error.options[:validator_type] == kwargs[:validator] || validator_sym
      end&.options

    expect(validator_error_options).not_to be_nil, "Expected validator error options to be present but got nil"

    expect(
      error_options.all? do |key, _value|
        validator_error_options.has_key?(key) &&
          value_is_equal_or_both_are_procs?(error_options[key], validator_error_options[key])
      end
    ).to be(true), "Expected validator error options to include #{error_options.inspect}\nbut got #{validator_error_options.inspect}"
  end

  def is_expected_to_include_error_message(message_key, with_locales: I18n.available_locales, **kwargs)
    with_locales.each do |locale|
      I18n.with_locale(locale) do
        subject.valid?(kwargs[:context])

        validator_error_messages =
          subject.errors.select do |error|
            error.options[:validator_type] == kwargs[:validator] || validator_sym
          end.map(&:message)

        message = kwargs[:error_options][:custom_message] || I18n.t("errors.messages.#{message_key}", **kwargs[:error_options])

        expect(validator_error_messages).to include(message),
                                            "Expected error messages to include '#{message.inspect}'\nbut got #{validator_error_messages.inspect}"
      end
    end
  end

  def is_expected_to_raise_error(error_class, message)
    expect { subject.valid? }.to raise_error(error_class, /#{Regexp.escape(message)}/)
  end

  def validator_class
    "ActiveStorageValidations::#{subject.class.name.sub(/::/, '').sub(/::.+/, '')}".constantize
  end

  def validator_sym
    begin
      validator_class.to_sym
    rescue NameError
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
