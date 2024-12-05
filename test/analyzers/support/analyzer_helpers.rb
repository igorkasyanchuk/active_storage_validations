# frozen_string_literal: true

module AnalyzerHelpers
  def is_expected_to_raise_error(error_class, message)
    begin
      subject
    rescue => e
      assert_equal(e.class, error_class)
      assert(e.message.include?(message))
    else
      raise StandardError, "It should raise an error but it does not raise any"
    end
  end
end
