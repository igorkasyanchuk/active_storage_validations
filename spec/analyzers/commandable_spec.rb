# frozen_string_literal: true

require "rails_helper"

RSpec.describe ActiveStorageValidations::ASVCommandable do
  let(:attachable) do
    {
      io: StringIO.new("hello"),
      filename: "hello.txt",
      content_type: "text/plain"
    }
  end
  let(:timeout) { 10.seconds }
  let(:analyzer) do
    ActiveStorageValidations::Analyzer::ContentTypeAnalyzer::File.new(attachable, timeout: timeout)
  end

  after do
    ActiveStorageValidations.command_timeout = 10.seconds
  end

  describe "#run_command" do
    subject(:command_result) { analyzer.send(:run_command, *argv, payload: payload) }

    let(:payload) { { analyzer: "test", timed_out: false } }

    context "when the command succeeds" do
      let(:argv) { [ "echo", "asv-ok" ] }

      it "returns a successful result with stdout" do
        expect(command_result.success?).to be(true)
        expect(command_result.stdout).to eq("asv-ok\n")
        expect(command_result.timed_out).to be(false)
      end
    end

    context "when the command exceeds the timeout" do
      let(:timeout) { 0.2 }
      let(:argv) { [ "ruby", "-e", "sleep 5" ] }

      it "kills the process and marks the result as timed out" do
        events = []
        subscriber = ActiveSupport::Notifications.subscribe("timeout.active_storage_validations") do |*args|
          events << ActiveSupport::Notifications::Event.new(*args)
        end

        expect(command_result.success?).to be(false)
        expect(command_result.timed_out).to be(true)
        expect(payload[:timed_out]).to be(true)
        expect(events.size).to eq(1)
        expect(events.first.payload[:command]).to eq("ruby")
        expect(events.first.payload[:timeout]).to be_within(0.001).of(0.2)
      ensure
        ActiveSupport::Notifications.unsubscribe(subscriber)
      end
    end

    context "when the command writes more than the pipe buffer then hangs" do
      let(:timeout) { 0.5 }
      # Without concurrent pipe draining this deadlocks: child blocks on write
      # while parent waits for exit.
      let(:argv) { [ "ruby", "-e", "print('x' * (1024 * 1024)); STDOUT.flush; sleep 10" ] }

      it "times out instead of deadlocking on a full pipe" do
        _measured, elapsed = measure { command_result }

        expect(command_result.timed_out).to be(true)
        expect(command_result.success?).to be(false)
        expect(elapsed).to be < 3.0
      end
    end

    context "when the command floods stderr then hangs" do
      let(:timeout) { 0.5 }
      let(:argv) { [ "ruby", "-e", "STDERR.write('y' * (1024 * 1024)); STDERR.flush; sleep 10" ] }

      it "times out instead of deadlocking on a full stderr pipe" do
        _measured, elapsed = measure { command_result }

        expect(command_result.timed_out).to be(true)
        expect(command_result.success?).to be(false)
        expect(elapsed).to be < 3.0
      end
    end

    context "when the command writes more than the pipe buffer and exits" do
      let(:timeout) { 10 }
      let(:argv) { [ "ruby", "-e", "print('x' * (1024 * 1024))" ] }

      it "captures the full stdout without hanging" do
        expect(command_result.success?).to be(true)
        expect(command_result.stdout.bytesize).to eq(1024 * 1024)
      end
    end

    context "when the command exits with a non-zero status" do
      let(:argv) { [ "ruby", "-e", "STDERR.print('nope'); exit 7" ] }

      it "is unsuccessful but not timed out" do
        expect(command_result.success?).to be(false)
        expect(command_result.timed_out).to be(false)
        expect(command_result.status.exitstatus).to eq(7)
        expect(command_result.stderr).to eq("nope")
      end
    end

    context "when the command ignores TERM" do
      let(:timeout) { 0.3 }
      # Use the shell: Ruby -e may still be booting when the short timeout fires,
      # so TERM arrives before Signal.trap(:TERM, "IGNORE") is installed and the
      # process dies immediately (flake under CI load). `trap "" TERM` is set
      # before exec, and IGNORE is inherited by sleep.
      let(:argv) { [ "sh", "-c", 'trap "" TERM; exec sleep 30' ] }

      it "escalates to KILL after the grace period" do
        _measured, elapsed = measure { command_result }
        grace = ActiveStorageValidations::ASVCommandable::TERM_GRACE_SECONDS

        expect(command_result.timed_out).to be(true)
        expect(command_result.success?).to be(false)
        # Must wait the full grace period — dying on TERM would finish near @timeout.
        expect(elapsed).to be >= timeout + grace - 0.2
        expect(elapsed).to be < timeout + grace + 1
      end
    end

    context "when the command spawns process-group grandchildren" do
      let(:timeout) { 0.3 }
      # Spawn via ruby so the grandchild shares the timed command's process group.
      # Print the grandchild pid so we can assert it was killed without pgrep
      # (pgrep -f races with the shell wrapper whose argv also contains the pattern).
      let(:argv) do
        [
          "ruby", "-e",
          'child = Process.spawn("sleep", "30"); puts "started #{child}"; STDOUT.flush; sleep 30'
        ]
      end

      it "kills grandchildren in the process group" do
        child_pid = nil
        child_pid = command_result.stdout[/\Astarted (\d+)\n\z/, 1].to_i

        expect(command_result.timed_out).to be(true)
        expect(child_pid).to be > 0, "expected grandchild pid in stdout, got #{command_result.stdout.inspect}"

        alive = process_alive?(child_pid)
        # Brief retry: kernel may need a tick to reap after KILL.
        5.times do
          break unless alive
          sleep 0.05
          alive = process_alive?(child_pid)
        end

        expect(alive).to be(false), "expected process-group kill to reap grandchild pid=#{child_pid}"
      ensure
        if child_pid&.positive? && process_alive?(child_pid)
          Process.kill(:KILL, child_pid) rescue nil
        end
      end
    end

    context "when timeout is disabled" do
      let(:timeout) { nil }
      let(:argv) { [ "echo", "no-timeout" ] }

      it "runs the command without a deadline" do
        expect(command_result.success?).to be(true)
        expect(command_result.stdout).to eq("no-timeout\n")
        expect(command_result.timed_out).to be(false)
      end
    end

    context "when the binary is missing" do
      let(:argv) { [ "asv_definitely_missing_binary_#{Process.pid}" ] }

      it "raises Errno::ENOENT" do
        expect { command_result }.to raise_error(Errno::ENOENT)
      end
    end
  end

  describe "timeout resolution" do
    subject(:result) { analyzer.send(:timeout_in_seconds) }

    before { ActiveStorageValidations.command_timeout = 3.seconds }

    context "when no instance timeout is given" do
      let(:analyzer) { ActiveStorageValidations::Analyzer::ContentTypeAnalyzer::File.new(attachable) }

      it { is_expected.to eq(3.0) }
    end

    context "when an instance timeout override is given" do
      let(:timeout) { 1.second }

      it { is_expected.to eq(1.0) }
    end

    context "when the instance timeout is nil" do
      let(:timeout) { nil }

      it { is_expected.to be_nil }
    end
  end

  describe "#wait_for_command" do
    it "returns as soon as a fast command exits (no polling sleep)" do
      result, elapsed = measure { analyzer.send(:run_command, "true", payload: {}) }

      expect(result.success?).to be(true)
      expect(result.timed_out).to be(false)
      # Bound must stay well under a polling-sleep interval, but leave headroom for
      # CI process-spawn latency (observed ~0.06–0.08s under load).
      expect(elapsed).to be < 0.25
    end

    it "reaps the process group after a timeout without leaving zombies" do
      pid = Process.spawn("ruby", "-e", "sleep 5", pgroup: true)
      status, timed_out = analyzer.send(:wait_for_command, pid, 0.2)

      expect(timed_out).to be(true)
      expect(status).to be_truthy
      expect { Process.wait2(pid, Process::WNOHANG) }.to raise_error(Errno::ECHILD)
    end
  end

  describe "ActiveStorageValidations.configure" do
    it "yields the module for configuration" do
      ActiveStorageValidations.configure do |config|
        config.command_timeout = 4.seconds
      end

      expect(ActiveStorageValidations.command_timeout).to eq(4.seconds)
    end
  end

  private

  def measure
    started_at = Process.clock_gettime(Process::CLOCK_MONOTONIC)
    result = yield
    elapsed = Process.clock_gettime(Process::CLOCK_MONOTONIC) - started_at
    [ result, elapsed ]
  end

  def process_alive?(pid)
    Process.kill(0, pid)
    true
  rescue Errno::ESRCH
    false
  rescue Errno::EPERM
    true
  end
end
