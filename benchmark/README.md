# Benchmarks

Informational performance suite for metadata validators (cold analysis vs cached `asv_*` hits), inspired by [faker-ruby’s approach](https://hexdevs.com/posts/optimizing-faker-ruby-autoload-openssl/).

These scripts measure wall-clock / iterations-per-second. They do **not** fail CI on regressions. Compare PR output or a local run against [`BASELINE.md`](BASELINE.md).

Correctness of the cache (“analyzer called once”) remains covered by `IsPerformanceOptimized` shared examples in the test suite.

## Setup

Benchmark gems live in the `:benchmark` Bundler group:

```bash
bundle config set --local with benchmark
bundle install
```

If you previously excluded the group:

```bash
bundle config unset --local without
# or remove `benchmark` from BUNDLE_WITHOUT
bundle install
```

## Run

From the gem root (default Gemfile / Rails from `Gemfile`):

```bash
bundle exec ruby benchmark/require.rb
IMAGE_PROCESSOR=vips bundle exec ruby benchmark/metadata_validators.rb
IMAGE_PROCESSOR=mini_magick bundle exec ruby benchmark/metadata_validators.rb
bundle exec ruby benchmark/image_processors.rb
```

Tune duration:

```bash
BENCH_TIME=5 BENCH_WARMUP=2 IMAGE_PROCESSOR=vips bundle exec ruby benchmark/metadata_validators.rb
```

## What is measured

| Report | Meaning |
|--------|---------|
| `require` | Time to `require "active_storage_validations"` after Rails/Active Storage are preloaded (Engine needs `Rails`) |
| `*/cold` | Attach fixture + first `valid?` (analyzer + persist `asv_*`) |
| `*/warm` | `valid?` on a saved record that already has `asv_*` metadata |
| `multi same keys` | `aspect_ratio` + `dimension` on one image |
| `multi different keys` | `dimension` + `content_type` spoofing on one video |
| `image_processors.rb` | Same-process head-to-head: cold image validators with `:vips` vs `:mini_magick` |

Fixtures are the same files under `test/dummy/public/` used by the test suite.

## Updating the baseline

1. Run `metadata_validators.rb` for both processors and `image_processors.rb`.
2. Paste the full stdout (including the environment header) into [`BASELINE.md`](BASELINE.md).
3. If the vips vs mini_magick ratio changes meaningfully, update the recommendation in the root [`README.md`](../README.md#using-image-metadata-validators).
4. Note machine / OS package versions already printed by the script.
5. In the PR that changes analyzer or validation hot paths, call out intentional regressions.

## Profiling with Vernier (local)

```bash
bundle exec vernier run -- bundle exec ruby benchmark/require.rb
bundle exec vernier run --interval 100 --allocation-interval 10 -- \
  IMAGE_PROCESSOR=vips bundle exec ruby -e 'load "benchmark/metadata_validators.rb"'
```

Vernier is for investigation, not CI gating.

## CI

[`.github/workflows/bench.yml`](../.github/workflows/bench.yml) runs the suite on push/PR and uploads a `benchmark-report` artifact. Numbers are informational only.
