module MatcherHelpers
  require 'active_storage_validations/matchers'

  def is_expected_to_match_for(klass)
    subject && assert(subject.matches?(klass))
  end

  def is_expected_not_to_match_for(klass)
    subject && refute(subject.matches?(klass))
  end

  def is_expected_to_raise_error(error_class, message)
    begin
      subject.matches?(klass)
    rescue => e
      assert_equal(e.class, error_class)
      assert(e.message.include?(message))
    else
      raise StandardError, "It should raise an error but it does not raise any"
    end
  end

  def is_expected_to_have_failure_message(expected_failure_message)
    subject.matches?(klass)
    assert_equal(subject.failure_message, expected_failure_message)
  end

  def is_expected_to_have_failure_message_when_negated(expected_failure_message)
    subject.matches?(klass)
    assert_equal(subject.failure_message_when_negated, expected_failure_message)
  end

  def validator_class
    subject.class.name.sub(/::Matchers/, '').sub(/Matcher/, '').constantize
  end

  def validator_sym
    validator_class.to_sym
  end
end
