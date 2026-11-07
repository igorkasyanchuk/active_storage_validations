# frozen_string_literal: true

require "digest"
require "open3"
require "json"

# Each Magika CLI run loads its model (~2.5s), so the real-upload matrix ran
# it ~170 times. `magika_batch(paths)` runs the real CLI once on every file of
# a group, and answers the analyzer's command with that file's own entry,
# looked up by content (the analyzer reads a tempfile copy). Files outside the
# batch still run the CLI.
module MagikaBatch
  def magika_batch(paths)
    before(:context) { MagikaBatch.load(paths) }
    after(:context) { MagikaBatch.reset }

    before do
      # rubocop:disable RSpec/AnyInstance -- one analyzer per attachable, built by the validator
      allow_any_instance_of(ActiveStorageValidations::Analyzer::ContentTypeAnalyzer::Magika)
        .to receive(:run_command).and_wrap_original do |original, *command, **options|
          entry = MagikaBatch.entry_for(command.last)
          entry ? MagikaBatch.command_result(entry) : original.call(*command, **options)
        end
      # rubocop:enable RSpec/AnyInstance
    end
  end

  class << self
    def load(paths)
      stdout, status = Open3.capture2("magika", "--json", *paths.map(&:to_s))
      raise "magika --json failed on the batch" unless status.success?

      @entries = JSON.parse(stdout).to_h { |entry| [ Digest::SHA256.file(entry.fetch("path")).hexdigest, entry ] }
    end

    def reset
      @entries = nil
    end

    def entry_for(path)
      @entries&.[](Digest::SHA256.file(path).hexdigest) if File.file?(path)
    end

    def command_result(entry)
      ActiveStorageValidations::ASVCommandable::CommandResult.new(
        stdout: JSON.generate([ entry ]),
        stderr: "",
        status: Struct.new(:success?).new(true),
        timed_out: false
      )
    end
  end
end

RSpec.configure { |config| config.extend MagikaBatch }
