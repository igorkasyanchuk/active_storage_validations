# frozen_string_literal: true

# Wall-clock / ips benchmarks for metadata validators (cold analysis vs cache hit).
#
#   IMAGE_PROCESSOR=vips bundle exec ruby benchmark/metadata_validators.rb
#   IMAGE_PROCESSOR=mini_magick bundle exec ruby benchmark/metadata_validators.rb
#
# Optional: BENCH_TIME=5 BENCH_WARMUP=2

require_relative "support/boot"

ASVBenchmark.print_environment_header

image = -> { ASVBenchmark.image_attachable }
audio = -> { ASVBenchmark.audio_attachable }
video = -> { ASVBenchmark.video_attachable }
pdf = -> { ASVBenchmark.pdf_attachable }

warm_dimension = ASVBenchmark.prepare_warm(
  Dimension::Validator::IsPerformanceOptimized,
  :is_performance_optimized,
  image
)
warm_duration = ASVBenchmark.prepare_warm(
  Duration::Validator::IsPerformanceOptimized,
  :is_performance_optimized,
  audio
)
warm_pages = ASVBenchmark.prepare_warm(
  Pages::Validator::IsPerformanceOptimized,
  :is_performance_optimized,
  pdf
)
warm_content_type = ASVBenchmark.prepare_warm(
  ContentType::Validator::IsPerformanceOptimized,
  :is_performance_optimized,
  image
)
warm_processable = ASVBenchmark.prepare_warm(
  ProcessableFile::Validator::IsPerformanceOptimized,
  :is_performance_optimized,
  image
)
warm_multi_same = ASVBenchmark.prepare_warm(
  Integration::Validator::Performance,
  :pictures,
  image
)
warm_multi_diff = ASVBenchmark.prepare_warm(
  Integration::Validator::Performance,
  :videos,
  video
)

Benchmark.ips do |x|
  x.config(**ASVBenchmark.ips_config)

  x.report("dimension/image cold") do
    ASVBenchmark.cold_validate(
      Dimension::Validator::IsPerformanceOptimized,
      :is_performance_optimized,
      image
    )
  end
  x.report("dimension/image warm") { warm_dimension.valid? }

  x.report("duration/audio cold") do
    ASVBenchmark.cold_validate(
      Duration::Validator::IsPerformanceOptimized,
      :is_performance_optimized,
      audio
    )
  end
  x.report("duration/audio warm") { warm_duration.valid? }

  x.report("pages/pdf cold") do
    ASVBenchmark.cold_validate(
      Pages::Validator::IsPerformanceOptimized,
      :is_performance_optimized,
      pdf
    )
  end
  x.report("pages/pdf warm") { warm_pages.valid? }

  x.report("content_type spoof cold") do
    ASVBenchmark.cold_validate(
      ContentType::Validator::IsPerformanceOptimized,
      :is_performance_optimized,
      image
    )
  end
  x.report("content_type spoof warm") { warm_content_type.valid? }

  x.report("processable_file/image cold") do
    ASVBenchmark.cold_validate(
      ProcessableFile::Validator::IsPerformanceOptimized,
      :is_performance_optimized,
      image
    )
  end
  x.report("processable_file/image warm") { warm_processable.valid? }

  x.report("multi same keys cold (aspect_ratio+dimension)") do
    ASVBenchmark.cold_validate(
      Integration::Validator::Performance,
      :pictures,
      image
    )
  end
  x.report("multi same keys warm") { warm_multi_same.valid? }

  x.report("multi different keys cold (dimension+content_type)") do
    ASVBenchmark.cold_validate(
      Integration::Validator::Performance,
      :videos,
      video
    )
  end
  x.report("multi different keys warm") { warm_multi_diff.valid? }

  x.compare!
end
