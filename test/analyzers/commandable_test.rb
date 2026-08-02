# frozen_string_literal: true

require "test_helper"

describe ActiveStorageValidations::ASVCommandable do
  let(:attachable) do
    {
      io: StringIO.new("hello"),
      filename: "hello.txt",
      content_type: "text/plain"
    }
  end
  let(:timeout) { 10.seconds }
  let(:analyzer) do
    ActiveStorageValidations::Analyzer::ContentTypeAnalyzer.new(attachable, timeout: timeout)
  end

  after do
    ActiveStorageValidations.command_timeout = 10.seconds
  end

  describe "#run_command" do
    subject { analyzer.send(:run_command, *argv, payload: payload) }

    let(:payload) { { analyzer: "test", timed_out: false } }

    describe "when the command succeeds" do
      let(:argv) { [ "echo", "asv-ok" ] }

      it "returns a successful result with stdout" do
        result = subject

        assert result.success?
        assert_equal "asv-ok\n", result.stdout
        refute result.timed_out
      end
    end

    describe "when the command exceeds the timeout" do
      let(:timeout) { 0.2 }
      let(:argv) { [ "ruby", "-e", "sleep 5" ] }

      it "kills the process and marks the result as timed out" do
        events = []
        subscriber = ActiveSupport::Notifications.subscribe("timeout.active_storage_validations") do |*args|
          events << ActiveSupport::Notifications::Event.new(*args)
        end

        result = subject

        refute result.success?
        assert result.timed_out
        assert payload[:timed_out]
        assert_equal 1, events.size
        assert_equal "ruby", events.first.payload[:command]
        assert_in_delta 0.2, events.first.payload[:timeout], 0.001
      ensure
        ActiveSupport::Notifications.unsubscribe(subscriber)
      end
    end

    describe "when the command writes more than the pipe buffer then hangs" do
      let(:timeout) { 0.5 }
      # Without concurrent pipe draining this deadlocks: child blocks on write
      # while parent waits for exit.
      let(:argv) { [ "ruby", "-e", "print('x' * (1024 * 1024)); STDOUT.flush; sleep 10" ] }

      it "times out instead of deadlocking on a full pipe" do
        started_at = Process.clock_gettime(Process::CLOCK_MONOTONIC)
        result = subject
        elapsed = Process.clock_gettime(Process::CLOCK_MONOTONIC) - started_at

        assert result.timed_out
        refute result.success?
        assert_operator elapsed, :<, 3.0
      end
    end

    describe "when the command floods stderr then hangs" do
      let(:timeout) { 0.5 }
      let(:argv) { [ "ruby", "-e", "STDERR.write('y' * (1024 * 1024)); STDERR.flush; sleep 10" ] }

      it "times out instead of deadlocking on a full stderr pipe" do
        started_at = Process.clock_gettime(Process::CLOCK_MONOTONIC)
        result = subject
        elapsed = Process.clock_gettime(Process::CLOCK_MONOTONIC) - started_at

        assert result.timed_out
        refute result.success?
        assert_operator elapsed, :<, 3.0
      end
    end

    describe "when the command writes more than the pipe buffer and exits" do
      let(:timeout) { 10 }
      let(:argv) { [ "ruby", "-e", "print('x' * (1024 * 1024))" ] }

      it "captures the full stdout without hanging" do
        result = subject

        assert result.success?
        assert_equal 1024 * 1024, result.stdout.bytesize
      end
    end

    describe "when the command exits with a non-zero status" do
      let(:argv) { [ "ruby", "-e", "STDERR.print('nope'); exit 7" ] }

      it "is unsuccessful but not timed out" do
        result = subject

        refute result.success?
        refute result.timed_out
        assert_equal 7, result.status.exitstatus
        assert_equal "nope", result.stderr
      end
    end

    describe "when the command ignores TERM" do
      let(:timeout) { 0.2 }
      let(:argv) { [ "ruby", "-e", "Signal.trap(:TERM) {}; sleep 30" ] }

      it "escalates to KILL after the grace period" do
        started_at = Process.clock_gettime(Process::CLOCK_MONOTONIC)
        result = subject
        elapsed = Process.clock_gettime(Process::CLOCK_MONOTONIC) - started_at
        grace = ActiveStorageValidations::ASVCommandable::TERM_GRACE_SECONDS

        assert result.timed_out
        refute result.success?
        assert_in_delta timeout + grace, elapsed, 0.4
        assert_operator elapsed, :<, timeout + grace + 1
      end
    end

    describe "when the command spawns process-group grandchildren" do
      let(:timeout) { 0.3 }
      # Distinctive sleep duration so pgrep does not collide with other tests.
      let(:argv) { [ "sh", "-c", "sleep 37.137 & echo started; wait" ] }

      it "kills grandchildren in the process group" do
        result = subject
        sleep 0.3
        leftover = `pgrep -f "sleep 37.137" 2>/dev/null`.lines.map(&:strip).reject(&:empty?)

        assert result.timed_out
        assert_equal "started\n", result.stdout
        assert_empty leftover, "expected process-group kill to reap grandchildren, leftover=#{leftover.inspect}"
      end
    end

    describe "when timeout is disabled" do
      let(:timeout) { nil }
      let(:argv) { [ "echo", "no-timeout" ] }

      it "runs the command without a deadline" do
        result = subject

        assert result.success?
        assert_equal "no-timeout\n", result.stdout
        refute result.timed_out
      end
    end

    describe "when the binary is missing" do
      let(:argv) { [ "asv_definitely_missing_binary_#{Process.pid}" ] }

      it "raises Errno::ENOENT" do
        assert_raises(Errno::ENOENT) { subject }
      end
    end
  end

  describe "timeout resolution" do
    it "uses the global command_timeout by default" do
      ActiveStorageValidations.command_timeout = 3.seconds
      analyzer = ActiveStorageValidations::Analyzer::ContentTypeAnalyzer.new(attachable)

      assert_equal 3.0, analyzer.send(:timeout_in_seconds)
    end

    it "uses the instance timeout override" do
      ActiveStorageValidations.command_timeout = 3.seconds
      analyzer = ActiveStorageValidations::Analyzer::ContentTypeAnalyzer.new(attachable, timeout: 1.second)

      assert_equal 1.0, analyzer.send(:timeout_in_seconds)
    end

    it "allows nil to disable the timeout" do
      ActiveStorageValidations.command_timeout = 3.seconds
      analyzer = ActiveStorageValidations::Analyzer::ContentTypeAnalyzer.new(attachable, timeout: nil)

      assert_nil analyzer.send(:timeout_in_seconds)
    end
  end

  describe "#wait_for_command" do
    it "returns as soon as a fast command exits (no polling sleep)" do
      started_at = Process.clock_gettime(Process::CLOCK_MONOTONIC)
      result = analyzer.send(:run_command, "true", payload: {})
      elapsed = Process.clock_gettime(Process::CLOCK_MONOTONIC) - started_at

      assert result.success?
      refute result.timed_out
      assert_operator elapsed, :<, 0.05
    end

    it "reaps the process group after a timeout without leaving zombies" do
      pid = Process.spawn("ruby", "-e", "sleep 5", pgroup: true)
      status, timed_out = analyzer.send(:wait_for_command, pid, 0.2)

      assert timed_out
      assert status
      assert_raises(Errno::ECHILD) { Process.wait2(pid, Process::WNOHANG) }
    end
  end

  describe "ActiveStorageValidations.configure" do
    it "yields the module for configuration" do
      ActiveStorageValidations.configure do |config|
        config.command_timeout = 4.seconds
      end

      assert_equal 4.seconds, ActiveStorageValidations.command_timeout
    end
  end
end
