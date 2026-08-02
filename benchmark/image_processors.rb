# frozen_string_literal: true

# Head-to-head cold analysis: libvips vs MiniMagick/ImageMagick for image
# metadata validators (dimension, processable_file, aspect_ratio+dimension).
#
# Switches ActiveStorage.variant_processor per report in one process so the
# comparison is fair (same Ruby/Rails/fixtures/machine).
#
#   bundle exec ruby benchmark/image_processors.rb
#
# Optional: BENCH_TIME=5 BENCH_WARMUP=2

require_relative "support/boot"

ASVBenchmark.print_environment_header
puts "Note: IMAGE_PROCESSOR env is ignored here; each report sets the processor explicitly."
puts

image = -> { ASVBenchmark.image_attachable }

Benchmark.ips do |x|
  x.config(**ASVBenchmark.ips_config)

  x.report("dimension/image cold (vips)") do
    ASVBenchmark.cold_validate_with_processor(
      :vips,
      Dimension::Validator::IsPerformanceOptimized,
      :is_performance_optimized,
      image
    )
  end
  x.report("dimension/image cold (mini_magick)") do
    ASVBenchmark.cold_validate_with_processor(
      :mini_magick,
      Dimension::Validator::IsPerformanceOptimized,
      :is_performance_optimized,
      image
    )
  end

  x.report("processable_file/image cold (vips)") do
    ASVBenchmark.cold_validate_with_processor(
      :vips,
      ProcessableFile::Validator::IsPerformanceOptimized,
      :is_performance_optimized,
      image
    )
  end
  x.report("processable_file/image cold (mini_magick)") do
    ASVBenchmark.cold_validate_with_processor(
      :mini_magick,
      ProcessableFile::Validator::IsPerformanceOptimized,
      :is_performance_optimized,
      image
    )
  end

  x.report("aspect_ratio/image cold (vips)") do
    ASVBenchmark.cold_validate_with_processor(
      :vips,
      AspectRatio::Validator::IsPerformanceOptimized,
      :is_performance_optimized,
      image
    )
  end
  x.report("aspect_ratio/image cold (mini_magick)") do
    ASVBenchmark.cold_validate_with_processor(
      :mini_magick,
      AspectRatio::Validator::IsPerformanceOptimized,
      :is_performance_optimized,
      image
    )
  end

  x.report("multi same keys cold (vips)") do
    ASVBenchmark.cold_validate_with_processor(
      :vips,
      Integration::Validator::Performance,
      :pictures,
      image
    )
  end
  x.report("multi same keys cold (mini_magick)") do
    ASVBenchmark.cold_validate_with_processor(
      :mini_magick,
      Integration::Validator::Performance,
      :pictures,
      image
    )
  end

  x.compare!
end
