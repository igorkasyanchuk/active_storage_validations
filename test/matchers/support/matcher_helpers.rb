module MatcherHelpers
  require 'active_storage_validations/matchers'

  def is_expected_to_match_for(klass)
    subject && assert(subject.matches?(klass))
  end

  def is_expected_not_to_match_for(klass)
    subject && refute(subject.matches?(klass))
  end

  def is_expected_to_raise_error(error_class, message)
    begin subject.matches?(klass)
    rescue => e
      assert_equal(e.class, error_class)
      assert(e.message.include?(message))
    end
  end

  def validator_class
    subject.class.name.sub(/::Matchers/, '').sub(/Matcher/, '').constantize
  end

  def validator_sym
    validator_class.to_sym
  end
end
