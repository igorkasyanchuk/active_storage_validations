# frozen_string_literal: true

# Analyzers copy attachables without a usable path to a tempfile named
# "ActiveStorageValidations-…" (Analyzer#create_media_tempfile) and must delete
# it, whether the analysis succeeds, fails or times out. Fail the run when one
# is left behind. Files that already existed (another run) are ignored.
module MediaTempfileLeaks
  PATTERN = File.join(Dir.tmpdir, "ActiveStorageValidations-*")

  def self.snapshot!
    @existing = Dir[PATTERN]
  end

  def self.check!
    leftover = Dir[PATTERN] - @existing.to_a
    return if leftover.empty?

    raise "Analyzer tempfiles left behind (Analyzer#create_media_tempfile must delete them): #{leftover.join(', ')}"
  end
end

RSpec.configure do |config|
  config.before(:suite) { MediaTempfileLeaks.snapshot! }
  config.after(:suite) { MediaTempfileLeaks.check! }
end
