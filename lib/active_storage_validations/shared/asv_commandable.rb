# frozen_string_literal: true

module ActiveStorageValidations
  # ActiveStorageValidations::ASVCommandable
  #
  # Runs external analyzer commands with an optional deadline and process-group
  # kill. Used by analyzers that shell out (ffprobe, pdfinfo, file, identify).
  module ASVCommandable
    extend ActiveSupport::Concern

    CommandResult = Struct.new(:stdout, :stderr, :status, :timed_out, keyword_init: true) do
      def success?
        !timed_out && status.respond_to?(:success?) && status.success?
      end
    end

    TERM_GRACE_SECONDS = 1

    private

    def run_command(*argv, payload: nil)
      timeout = timeout_in_seconds
      stdout_reader, stdout_writer = IO.pipe
      stderr_reader, stderr_writer = IO.pipe

      pid = Process.spawn(*argv.map(&:to_s), out: stdout_writer, err: stderr_writer, **process_group_spawn_options)
      waiter = reap_in_background(pid)
      stdout_writer.close
      stderr_writer.close

      # Drain pipes concurrently so a chatty child cannot fill the buffer and
      # deadlock while we wait / kill it.
      stdout_thread = pipe_reader(stdout_reader)
      stderr_thread = pipe_reader(stderr_reader)

      status, timed_out = wait_for_command(pid, waiter, timeout)
      mark_timed_out!(payload, argv.first) if timed_out

      CommandResult.new(
        stdout: stdout_thread.value,
        stderr: stderr_thread.value,
        status: status,
        timed_out: timed_out
      )
    ensure
      # An exception raised into this thread while it waits (Thread#raise from
      # Rack::Timeout, a job shutdown, …) must not leave the command running:
      # kill it, the waiter thread still reaps it.
      signal_process_group(pid, :KILL) if waiter&.alive?
      close_pipe(stdout_reader)
      close_pipe(stderr_reader)
      close_pipe(stdout_writer)
      close_pipe(stderr_writer)
    end

    # The waiter thread reaps the child whatever happens to the caller, so we
    # never leave zombies.
    def reap_in_background(pid)
      Thread.new do
        Process.wait2(pid).last
      rescue Errno::ECHILD
        nil
      end
    end

    # Closing the pipes after an interrupt makes a pending #read raise IOError
    # in its thread; nobody reads that thread's value any more.
    def pipe_reader(io)
      Thread.new { io.read }.tap { |thread| thread.report_on_exception = false }
    end

    # Waits via Thread#join(timeout) so fast commands return as soon as they
    # exit (no polling sleep); a nil timeout waits for good. On timeout, TERM
    # then always KILL the process group — KILL is unconditional because the
    # direct child can exit on TERM while a grandchild forked after the group
    # signal is still alive.
    def wait_for_command(pid, waiter, timeout)
      return [ waiter.value, false ] if waiter.join(timeout)

      signal_process_group(pid, :TERM)
      waiter.join(TERM_GRACE_SECONDS)
      signal_process_group(pid, :KILL)
      waiter.join

      [ waiter.value, true ]
    end

    # Run the command in its own process group so a timeout can take down the
    # whole tree. Windows has no POSIX process groups (`pgroup:` raises there):
    # `new_pgroup:` is the closest equivalent, and only the direct child is
    # killed (no TERM either — Ruby only implements KILL / INT on Windows).
    def process_group_spawn_options
      windows? ? { new_pgroup: true } : { pgroup: true }
    end

    def signal_process_group(pid, signal)
      windows? ? Process.kill(:KILL, pid) : Process.kill(signal, -pid)
    rescue Errno::ESRCH
      # Already exited; waiter will reap.
    end

    def windows?
      Gem.win_platform?
    end

    def close_pipe(io)
      io&.close unless io.nil? || io.closed?
    end

    def monotonic_time
      Process.clock_gettime(Process::CLOCK_MONOTONIC)
    end
  end
end
