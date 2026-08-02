# frozen_string_literal: true

module MatcherHelpers
  require "active_storage_validations/matchers"

  def is_expected_to_match_for(klass)
    expect(subject.matches?(klass)).to be(true)
  end

  def is_expected_not_to_match_for(klass)
    expect(subject.matches?(klass)).to be(false)
  end

  def is_expected_to_raise_error(error_class, message)
    expect { subject.matches?(klass) }.to raise_error(error_class, /#{Regexp.escape(message)}/)
  end

  def is_expected_to_have_failure_message(expected_failure_message)
    subject.matches?(klass)
    expect(subject.failure_message).to eq(expected_failure_message)
  end

  def is_expected_to_have_failure_message_when_negated(expected_failure_message)
    subject.matches?(klass)
    expect(subject.failure_message_when_negated).to eq(expected_failure_message)
  end

  def validator_class
    subject.class.name.sub(/::Matchers/, "").sub(/Matcher/, "").constantize
  end

  def validator_sym
    validator_class.to_sym
  end
end
