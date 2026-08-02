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

      pid = Process.spawn(*argv.map(&:to_s), out: stdout_writer, err: stderr_writer, pgroup: true)
      stdout_writer.close
      stderr_writer.close

      # Drain pipes concurrently so a chatty child cannot fill the buffer and
      # deadlock while we wait / kill it.
      stdout_thread = Thread.new { stdout_reader.read }
      stderr_thread = Thread.new { stderr_reader.read }

      status, timed_out = wait_for_command(pid, timeout)
      mark_timed_out!(payload, argv.first) if timed_out

      CommandResult.new(
        stdout: stdout_thread.value,
        stderr: stderr_thread.value,
        status: status,
        timed_out: timed_out
      )
    ensure
      close_pipe(stdout_reader)
      close_pipe(stderr_reader)
      close_pipe(stdout_writer)
      close_pipe(stderr_writer)
    end

    # Waits via a reaper thread + Thread#join(timeout) so fast commands return
    # as soon as they exit (no polling sleep). On timeout, TERM then always KILL
    # the process group — KILL is unconditional because the direct child can exit
    # on TERM while a grandchild forked after the group signal is still alive.
    # The same waiter reaps so we never leave zombies.
    def wait_for_command(pid, timeout)
      return [ Process.wait2(pid)[1], false ] if timeout.nil?

      waiter = Thread.new do
        Process.wait2(pid)
      rescue Errno::ECHILD
        nil
      end

      if waiter.join(timeout)
        return [ wait_status_from(waiter), false ]
      end

      signal_process_group(pid, :TERM)
      waiter.join(TERM_GRACE_SECONDS)
      signal_process_group(pid, :KILL)
      waiter.join

      [ wait_status_from(waiter), true ]
    end

    def wait_status_from(waiter)
      waiter.value&.last
    end

    def signal_process_group(pid, signal)
      Process.kill(signal, -pid)
    rescue Errno::ESRCH
      # Already exited; waiter will reap.
    end

    def close_pipe(io)
      io&.close unless io.nil? || io.closed?
    end

    def monotonic_time
      Process.clock_gettime(Process::CLOCK_MONOTONIC)
    end
  end
end
