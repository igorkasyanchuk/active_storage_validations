module ValidatorHelpers
  def is_expected_to_be_valid(**kwargs)
    subject && assert(subject.valid?(kwargs[:context]))
  end

  def is_expected_not_to_be_valid(**kwargs)
    subject && refute(subject.valid?(kwargs[:context]))
  end

  def is_expected_to_have_error_options(error_options, **kwargs)
    subject.valid?(kwargs[:context])

    # Rails 6.1.0 changes the form of ActiveModel’s errors collection
    # https://github.com/rails/rails/blob/6-1-stable/activemodel/CHANGELOG.md#rails-610-december-09-2020
    validator_errors = if Rails.gem_version >= Gem::Version.new('6.1.0')
      subject.errors.find { |error| error.options[:validator_type] == validator_sym }.options
    else
      # For errors before Rails 6.1.0 we do not have error options
      return true
    end

    assert(
      error_options.all? do |key, _value|
        validator_errors.has_key?(key) &&
          value_is_equal_or_both_are_procs?(error_options[key], validator_errors[key])
      end
    )
  end

  def is_expected_to_have_error_message(message_key, **kwargs)
    subject.valid?(kwargs[:context])

    # Rails 6.1.0 changes the form of ActiveModel’s errors collection
    # https://github.com/rails/rails/blob/6-1-stable/activemodel/CHANGELOG.md#rails-610-december-09-2020
    validator_error_message = if Rails.gem_version >= Gem::Version.new('6.1.0')
      subject.errors.find { |error| error.options[:validator_type] == validator_sym }.message
    else
      # For errors before Rails 6.1.0 we do not have error options
      return true
    end

    message = kwargs[:error_options][:custom_message] || I18n.t("errors.messages.#{message_key}", **kwargs[:error_options])

    assert_equal(message, validator_error_message)
  end

  def is_expected_to_raise_error(error_class, message)
    begin subject.valid?
    rescue => e
      assert_equal(e.class, error_class)
      assert(e.message.include?(message))
    end
  end

  def validator_class
    "ActiveStorageValidations::#{subject.class.name.sub(/::/, '').sub(/::.+/, '')}".constantize
  end

  def validator_sym
    validator_class.to_sym
  end

  private

  def value_is_equal_or_both_are_procs?(value_1, value_2)
    # Comparing Procs is tricky, let's just ensure that both values are procs
    # for now to check equality, if necessary we will investigate a better
    # solution
    (value_1 == value_2) || (value_1.is_a?(Proc) && value_2.is_a?(Proc))
  end
end
