# frozen_string_literal: true

# Lean Combustion boot for benchmark scripts (no SimpleCov / Minitest).
#
# Usage from a script in benchmark/:
#   require_relative "support/boot"

require "bundler/setup"

ENV["RAILS_ENV"] ||= "test"
ENV["IMAGE_PROCESSOR"] ||= "vips"

root = File.expand_path("../..", __dir__)
$LOAD_PATH.unshift(File.join(root, "lib")) unless $LOAD_PATH.include?(File.join(root, "lib"))

require "combustion"
Combustion.path = "test/dummy"
Combustion.initialize! :active_record, :active_storage, :active_job do
  config.active_storage.variant_processor = ENV["IMAGE_PROCESSOR"]&.to_sym
  config.active_job.queue_adapter = :inline
  # Same rationale as test/test_helper.rb — avoid PreviewImageJob / image_processing.
  config.active_storage.previewers = []
end

require "benchmark/ips"

module ASVBenchmark
  module_function

  PUBLIC_DIR = File.expand_path("../../test/dummy/public", __dir__)

  def attachable(filename, content_type)
    path = File.join(PUBLIC_DIR, filename)
    {
      io: File.open(path),
      filename: filename,
      content_type: content_type
    }
  end

  def image_attachable
    attachable("image_150x150.png", "image/png")
  end

  def audio_attachable
    attachable("audio.mp3", "audio/mp3")
  end

  def video_attachable
    # 150x150 so Integration::Validator::Performance dimension bounds pass.
    attachable("video_150x150.mp4", "video/mp4")
  end

  def pdf_attachable
    attachable("pdf_150x150.pdf", "application/pdf")
  end

  def close_attachable(attachable)
    io = attachable && attachable[:io]
    io.close if io && !io.closed?
  end

  # Temporarily set ActiveStorage.variant_processor (drives ASV image analyzer choice).
  def with_image_processor(processor)
    previous = ActiveStorage.variant_processor
    ActiveStorage.variant_processor = processor
    yield
  ensure
    ActiveStorage.variant_processor = previous
  end

  # First validation after attach — triggers analyzer + asv_* persistence.
  def cold_validate(model_class, attachment_name, attachable_proc)
    attachable = attachable_proc.call
    record = model_class.new
    record.public_send(attachment_name).attach(attachable)
    record.valid?
  ensure
    close_attachable(attachable)
  end

  def cold_validate_with_processor(processor, model_class, attachment_name, attachable_proc)
    with_image_processor(processor) do
      cold_validate(model_class, attachment_name, attachable_proc)
    end
  end

  # Record already saved with asv_* metadata — validation should hit the cache.
  def prepare_warm(model_class, attachment_name, attachable_proc)
    attachable = attachable_proc.call
    record = model_class.new
    record.public_send(attachment_name).attach(attachable)
    unless record.valid?
      raise "warm setup invalid for #{model_class}: #{record.errors.full_messages.join(', ')}"
    end
    record.save!
    record.reload
    record
  ensure
    close_attachable(attachable)
  end

  def print_environment_header
    puts "=" * 72
    puts "active_storage_validations benchmarks"
    puts "ruby:            #{RUBY_DESCRIPTION}"
    puts "rails:           #{Rails.version}"
    puts "IMAGE_PROCESSOR: #{ActiveStorage.variant_processor || :mini_magick}"
    puts "BUNDLE_GEMFILE:  #{ENV.fetch('BUNDLE_GEMFILE', '(default Gemfile)')}"
    puts "host:            #{`uname -nms`.strip}"
    puts "vips:            #{tool_version('vips', '-v')}"
    puts "ffmpeg:          #{tool_version('ffmpeg', '-version')}"
    puts "pdfinfo:         #{tool_version('pdfinfo', '-v')}"
    puts "file:            #{tool_version('file', '--version')}"
    puts "identify:        #{tool_version('identify', '-version')}"
    puts "time:            #{Time.now.utc.iso8601}"
    puts "=" * 72
    puts
  end

  def tool_version(bin, flag)
    out = `#{bin} #{flag} 2>&1`.lines.first.to_s.strip
    out.empty? ? "(not found)" : out
  rescue Errno::ENOENT
    "(not found)"
  end

  def ips_config
    {
      time: ENV.fetch("BENCH_TIME", "3").to_i,
      warmup: ENV.fetch("BENCH_WARMUP", "1").to_i
    }
  end
end
