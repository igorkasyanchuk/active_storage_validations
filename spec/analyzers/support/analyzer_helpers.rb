# frozen_string_literal: true

# Intentionally uses RSpec's `subject` API so shared helpers work with any named
# subject (`:metadata`, …). RSpec/NamedSubject only scans examples/hooks, not
# helper methods — no RuboCop disable needed here.
module AnalyzerHelpers
  def is_expected_to_raise_error(error_class, message)
    expect { subject }.to raise_error(error_class, /#{Regexp.escape(message)}/)
  end

  def timed_out_command_result
    ActiveStorageValidations::ASVCommandable::CommandResult.new(
      stdout: "",
      stderr: "",
      status: nil,
      timed_out: true
    )
  end
end
