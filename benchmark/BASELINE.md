# Performance baseline

Checked-in snapshot of `benchmark/` output. Update when landing analyzer / metadata-validator changes, or periodically.

How to refresh: see [README.md](README.md#updating-the-baseline).

**Machine:** Apple Silicon MacBook Air (`Darwin arm64`), 2026-08-02  
**Ruby / Rails:** 3.4.9 / 8.1.2 (default Gemfile)  
**BENCH_TIME / BENCH_WARMUP:** 3 / 1

---

## require

```
ruby: ruby 3.4.9 (2026-03-11 revision 76cca827ab) +PRISM [arm64-darwin24]
rails: 8.1.2 (preloaded; not included in timing)
took 19.917ms to load active_storage_validations
```

---

## metadata_validators — IMAGE_PROCESSOR=vips

```
========================================================================
active_storage_validations benchmarks
ruby:            ruby 3.4.9 (2026-03-11 revision 76cca827ab) +PRISM [arm64-darwin24]
rails:           8.1.2
IMAGE_PROCESSOR: vips
BUNDLE_GEMFILE:  (default Gemfile)
host:            Darwin arm64
vips:            vips-8.18.4
ffmpeg:          ffmpeg version 8.1.2
pdfinfo:         pdfinfo version 26.07.0
file:            file-5.41
identify:        ImageMagick 7.1.2-27
time:            2026-08-02T11:26:27Z
========================================================================

Calculating -------------------------------------
                              dimension/image cold    609.689 (±14.6%) i/s    (1.64 ms/i) -      1.890k in   3.099942s
                              dimension/image warm      3.343k (± 3.2%) i/s  (299.09 μs/i) -     10.263k in   3.069611s
                               duration/audio cold     28.504 (± 3.5%) i/s   (35.08 ms/i) -     87.000 in   3.052193s
                               duration/audio warm      3.383k (± 5.6%) i/s  (295.61 μs/i) -     10.164k in   3.004532s
                                    pages/pdf cold     46.390 (± 4.3%) i/s   (21.56 ms/i) -    140.000 in   3.017868s
                                    pages/pdf warm      2.972k (±20.4%) i/s  (336.47 μs/i) -      8.950k in   3.011408s
                           content_type spoof cold    117.189 (± 4.3%) i/s    (8.53 ms/i) -    368.000 in   3.140235s
                           content_type spoof warm      3.379k (± 3.2%) i/s  (295.99 μs/i) -     10.230k in   3.027939s
                       processable_file/image cold    537.918 (±17.7%) i/s    (1.86 ms/i) -      1.647k in   3.061806s
                       processable_file/image warm      3.657k (± 3.1%) i/s  (273.42 μs/i) -     10.991k in   3.005182s
     multi same keys cold (aspect_ratio+dimension)    511.505 (±12.9%) i/s    (1.96 ms/i) -      1.586k in   3.100652s
                              multi same keys warm    992.516 (± 8.7%) i/s    (1.01 ms/i) -      3.030k in   3.052848s
multi different keys cold (dimension+content_type)     22.295 (±13.5%) i/s   (44.85 ms/i) -     68.000 in   3.049993s
                         multi different keys warm    912.046 (±12.9%) i/s    (1.10 ms/i) -      2.756k in   3.021778s

Comparison:
                       processable_file/image warm:     3657.3 i/s
                               duration/audio warm:     3382.9 i/s - same-ish: difference falls within error
                           content_type spoof warm:     3378.5 i/s - 1.08x  slower
                              dimension/image warm:     3343.4 i/s - 1.09x  slower
                                    pages/pdf warm:     2972.0 i/s - same-ish: difference falls within error
                              multi same keys warm:      992.5 i/s - 3.68x  slower
                         multi different keys warm:      912.0 i/s - 4.01x  slower
                              dimension/image cold:      609.7 i/s - 6.00x  slower
                       processable_file/image cold:      537.9 i/s - 6.80x  slower
     multi same keys cold (aspect_ratio+dimension):      511.5 i/s - 7.15x  slower
                           content_type spoof cold:      117.2 i/s - 31.21x  slower
                                    pages/pdf cold:       46.4 i/s - 78.84x  slower
                               duration/audio cold:       28.5 i/s - 128.31x  slower
multi different keys cold (dimension+content_type):       22.3 i/s - 164.04x  slower
```

---

## metadata_validators — IMAGE_PROCESSOR=mini_magick

```
========================================================================
active_storage_validations benchmarks
ruby:            ruby 3.4.9 (2026-03-11 revision 76cca827ab) +PRISM [arm64-darwin24]
rails:           8.1.2
IMAGE_PROCESSOR: mini_magick
BUNDLE_GEMFILE:  (default Gemfile)
host:            Darwin arm64
vips:            vips-8.18.4
ffmpeg:          ffmpeg version 8.1.2
pdfinfo:         pdfinfo version 26.07.0
file:            file-5.41
identify:        ImageMagick 7.1.2-27
time:            2026-08-02T11:27:26Z
========================================================================

Calculating -------------------------------------
                              dimension/image cold    104.762 (± 4.8%) i/s    (9.55 ms/i) -    315.000 in   3.006822s
                              dimension/image warm      3.475k (± 3.1%) i/s  (287.77 μs/i) -     10.675k in   3.071924s
                               duration/audio cold     34.129 (± 5.9%) i/s   (29.30 ms/i) -    105.000 in   3.076591s
                               duration/audio warm      3.546k (± 4.0%) i/s  (281.99 μs/i) -     10.980k in   3.096278s
                                    pages/pdf cold     58.183 (±10.3%) i/s   (17.19 ms/i) -    175.000 in   3.007761s
                                    pages/pdf warm      3.508k (± 4.5%) i/s  (285.04 μs/i) -     10.602k in   3.021997s
                           content_type spoof cold    189.264 (± 5.3%) i/s    (5.28 ms/i) -    578.000 in   3.053928s
                           content_type spoof warm      3.523k (± 3.2%) i/s  (283.81 μs/i) -     10.620k in   3.014104s
                       processable_file/image cold    102.369 (± 6.8%) i/s    (9.77 ms/i) -    310.000 in   3.028249s
                       processable_file/image warm      3.627k (± 9.4%) i/s  (275.68 μs/i) -     11.107k in   3.061960s
     multi same keys cold (aspect_ratio+dimension)     99.728 (± 7.0%) i/s   (10.03 ms/i) -    300.000 in   3.008180s
                              multi same keys warm      1.068k (± 3.4%) i/s  (936.32 μs/i) -      3.224k in   3.018705s
multi different keys cold (dimension+content_type)     27.272 (±11.0%) i/s   (36.67 ms/i) -     82.000 in   3.006765s
                         multi different keys warm      1.065k (± 3.0%) i/s  (938.89 μs/i) -      3.264k in   3.064529s

Comparison:
                       processable_file/image warm:     3627.4 i/s
                               duration/audio warm:     3546.2 i/s - same-ish: difference falls within error
                           content_type spoof warm:     3523.4 i/s - same-ish: difference falls within error
                                    pages/pdf warm:     3508.3 i/s - same-ish: difference falls within error
                              dimension/image warm:     3475.0 i/s - same-ish: difference falls within error
                              multi same keys warm:     1068.0 i/s - 3.40x  slower
                         multi different keys warm:     1065.1 i/s - 3.41x  slower
                           content_type spoof cold:      189.3 i/s - 19.17x  slower
                              dimension/image cold:      104.8 i/s - 34.63x  slower
                       processable_file/image cold:      102.4 i/s - 35.43x  slower
     multi same keys cold (aspect_ratio+dimension):       99.7 i/s - 36.37x  slower
                                    pages/pdf cold:       58.2 i/s - 62.35x  slower
                               duration/audio cold:       34.1 i/s - 106.29x  slower
multi different keys cold (dimension+content_type):       27.3 i/s - 133.01x  slower
```

---

## image_processors — vips vs mini_magick

Same-process head-to-head (`benchmark/image_processors.rb`). Cold image metadata validation only; processor switched via `ActiveStorage.variant_processor` per report.

**Summary (this machine):** libvips is about **8× faster** than MiniMagick for cold `dimension` / `processable_file` / `aspect_ratio` analysis (≈7.9×–9.2× depending on the report).

```
========================================================================
active_storage_validations benchmarks
ruby:            ruby 3.4.9 (2026-03-11 revision 76cca827ab) +PRISM [arm64-darwin24]
rails:           8.1.2
IMAGE_PROCESSOR: vips (env ignored; each report sets processor)
host:            Darwin arm64
vips:            vips-8.18.4
identify:        ImageMagick 7.1.2-27
time:            2026-08-02T11:32:47Z
========================================================================

Calculating -------------------------------------
              dimension/image cold (vips)    478.506 (±10.7%) i/s    (2.09 ms/i) -      1.488k in   3.109679s
       dimension/image cold (mini_magick)     58.134 (± 8.6%) i/s   (17.20 ms/i) -    180.000 in   3.096312s
       processable_file/image cold (vips)    399.980 (± 8.8%) i/s    (2.50 ms/i) -      1.219k in   3.047653s
processable_file/image cold (mini_magick)     60.829 (± 9.9%) i/s   (16.44 ms/i) -    189.000 in   3.107066s
           aspect_ratio/image cold (vips)    375.073 (±10.9%) i/s    (2.67 ms/i) -      1.134k in   3.023409s
    aspect_ratio/image cold (mini_magick)     56.158 (±10.7%) i/s   (17.81 ms/i) -    175.000 in   3.116181s
              multi same keys cold (vips)    426.290 (± 9.4%) i/s    (2.35 ms/i) -      1.296k in   3.040186s
       multi same keys cold (mini_magick)     52.299 (± 9.6%) i/s   (19.12 ms/i) -    162.000 in   3.097569s

Comparison:
              dimension/image cold (vips):      478.5 i/s
              multi same keys cold (vips):      426.3 i/s - same-ish: difference falls within error
       processable_file/image cold (vips):      400.0 i/s - same-ish: difference falls within error
           aspect_ratio/image cold (vips):      375.1 i/s - 1.28x  slower
processable_file/image cold (mini_magick):       60.8 i/s - 7.87x  slower
       dimension/image cold (mini_magick):       58.1 i/s - 8.23x  slower
    aspect_ratio/image cold (mini_magick):       56.2 i/s - 8.52x  slower
       multi same keys cold (mini_magick):       52.3 i/s - 9.15x  slower
```
