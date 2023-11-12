module ValidatorHelpers
  def is_expected_to_be_valid(**kwargs)
    subject && assert(subject.valid?(kwargs[:context]))
  end

  def is_expected_not_to_be_valid(**kwargs)
    subject && refute(subject.valid?(kwargs[:context]))
  end

  def validator_sym
    "ActiveStorageValidations::#{subject.class.name.sub(/::/, '')}".constantize.to_sym
  end
end
