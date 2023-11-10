module MatcherHelpers
  def is_expected_to_match_for(klass)
    subject && assert(subject.matches?(klass))
  end

  def is_expected_not_to_match_for(klass)
    subject && refute(subject.matches?(klass))
  end
end
