# Performance baseline

Checked-in snapshot of `benchmark/` output. Update when landing analyzer / metadata-validator changes, or periodically.

How to refresh: see [README.md](README.md#updating-the-baseline).

**Machine:** Apple Silicon MacBook Pro (`Darwin arm64`), 2026-11-26  
**Ruby / Rails:** 4.0.10 / 8.1.4.1 (default Gemfile)  
**BENCH_TIME / BENCH_WARMUP:** 3 / 1

The previous snapshot (2026-08-02) ran on another machine with Ruby 3.4.9, so compare against it only roughly.

**Database:** the SQLite sections run the dummy app's default database, in process. The PostgreSQL sections run the same suite against a local PostgreSQL 17 over TCP (`DATABASE_URL`): apps mostly run PostgreSQL, where each query is a round trip, larger still across a network.

Since the previous snapshot, warm validations (cached `asv_*` metadata) no longer query `active_storage_attachments`, and the first analysis of an upload with a file on disk no longer creates an unused tempfile. Before → after each change, on this machine (vips; the warm rows are the same for mini_magick, the cold ones are dominated by the `magick` command there):

| Report | Change | SQLite | PostgreSQL (localhost) |
|---|---|---|---|
| `dimension/image warm` | no attachment queries | 211 µs → 26 µs | 337 µs → 27 µs |
| `multi same keys warm` | no attachment queries | 685 µs → 6.9 µs | 1.11 ms → 6.7 µs |
| `dimension/image cold` | no attachment queries | 577 µs → 452 µs | 700 µs → 513 µs |
| `dimension/image cold` | no unused tempfile | 456 µs → 405 µs | 518 µs → 384 µs |
| `processable_file/image cold` | no unused tempfile | 446 µs → 377 µs | 482 µs → 382 µs |

---

## require

```
ruby: ruby 4.0.10 (2026-11-19 revision a704b7cd95) +PRISM [arm64-darwin25]
rails: 8.1.4.1 (preloaded; not included in timing)
took 12.279ms to load active_storage_validations
```

---

## metadata_validators — IMAGE_PROCESSOR=vips (SQLite)

```
========================================================================
active_storage_validations benchmarks
ruby:            ruby 4.0.10 (2026-11-19 revision a704b7cd95) +PRISM [arm64-darwin25]
rails:           8.1.4.1
IMAGE_PROCESSOR: vips
database:        SQLite 3.54.1
BUNDLE_GEMFILE:  (default Gemfile)
host:            Darwin arm64
vips:            vips-8.18.7
ffmpeg:          ffmpeg version 9.0.2
pdfinfo:         pdfinfo version 26.10.0
file:            file-5.41
identify:        ImageMagick 7.1.2-34
time:            2026-11-26T11:12:27Z
========================================================================

ruby 4.0.10 (2026-11-19 revision a704b7cd95) +PRISM [arm64-darwin25]
Calculating -------------------------------------
                              dimension/image cold      2.467k (±11.7%) i/s  (405.43 μs/i) -      7.448k in   3.019614s
                              dimension/image warm     36.606k (± 2.8%) i/s   (27.32 μs/i) -    110.664k in   3.023149s
                               duration/audio cold     41.239 (±12.1%) i/s   (24.25 ms/i) -    124.000 in   3.006874s
                               duration/audio warm     39.030k (± 8.0%) i/s   (25.62 μs/i) -    118.636k in   3.039628s
                                    pages/pdf cold     56.704 (±15.9%) i/s   (17.64 ms/i) -    174.000 in   3.068590s
                                    pages/pdf warm     26.960k (± 3.4%) i/s   (37.09 μs/i) -     80.910k in   3.001125s
                           content_type spoof cold    292.247 (± 6.5%) i/s    (3.42 ms/i) -    884.000 in   3.024840s
                           content_type spoof warm     37.659k (± 6.7%) i/s   (26.55 μs/i) -    113.790k in   3.021601s
                       processable_file/image cold      2.654k (± 4.7%) i/s  (376.74 μs/i) -      8.064k in   3.038059s
                       processable_file/image warm     46.298k (±10.0%) i/s   (21.60 μs/i) -    140.160k in   3.027362s
     multi same keys cold (aspect_ratio+dimension)      2.310k (± 8.9%) i/s  (432.84 μs/i) -      7.018k in   3.037669s
                              multi same keys warm    141.395k (± 8.4%) i/s    (7.07 μs/i) -    441.780k in   3.124431s
multi different keys cold (dimension+content_type)     34.855 (± 2.9%) i/s   (28.69 ms/i) -    105.000 in   3.012498s
                         multi different keys warm    143.040k (± 3.6%) i/s    (6.99 μs/i) -    441.570k in   3.087048s

Comparison:
                         multi different keys warm:   143039.6 i/s
                              multi same keys warm:   141395.3 i/s - same-ish: difference falls within error
                       processable_file/image warm:    46297.7 i/s - 3.09x  slower
                               duration/audio warm:    39029.8 i/s - 3.66x  slower
                           content_type spoof warm:    37658.8 i/s - 3.80x  slower
                              dimension/image warm:    36605.5 i/s - 3.91x  slower
                                    pages/pdf warm:    26959.9 i/s - 5.31x  slower
                       processable_file/image cold:     2654.3 i/s - 53.89x  slower
                              dimension/image cold:     2466.5 i/s - 57.99x  slower
     multi same keys cold (aspect_ratio+dimension):     2310.3 i/s - 61.91x  slower
                           content_type spoof cold:      292.2 i/s - 489.45x  slower
                                    pages/pdf cold:       56.7 i/s - 2522.58x  slower
                               duration/audio cold:       41.2 i/s - 3468.56x  slower
multi different keys cold (dimension+content_type):       34.9 i/s - 4103.87x  slower
```

---

## metadata_validators — IMAGE_PROCESSOR=mini_magick (SQLite)

```
========================================================================
active_storage_validations benchmarks
ruby:            ruby 4.0.10 (2026-11-19 revision a704b7cd95) +PRISM [arm64-darwin25]
rails:           8.1.4.1
IMAGE_PROCESSOR: mini_magick
database:        SQLite 3.54.1
BUNDLE_GEMFILE:  (default Gemfile)
host:            Darwin arm64
vips:            vips-8.18.7
ffmpeg:          ffmpeg version 9.0.2
pdfinfo:         pdfinfo version 26.10.0
file:            file-5.41
identify:        ImageMagick 7.1.2-34
time:            2026-11-26T11:16:19Z
========================================================================

ruby 4.0.10 (2026-11-19 revision a704b7cd95) +PRISM [arm64-darwin25]
Calculating -------------------------------------
                              dimension/image cold    132.867 (± 5.3%) i/s    (7.53 ms/i) -    408.000 in   3.070751s
                              dimension/image warm     35.523k (± 2.2%) i/s   (28.15 μs/i) -    109.650k in   3.086769s
                               duration/audio cold     42.648 (± 7.0%) i/s   (23.45 ms/i) -    128.000 in   3.001294s
                               duration/audio warm     38.560k (± 2.9%) i/s   (25.93 μs/i) -    118.500k in   3.073130s
                                    pages/pdf cold     70.267 (± 5.7%) i/s   (14.23 ms/i) -    217.000 in   3.088233s
                                    pages/pdf warm     26.261k (± 2.9%) i/s   (38.08 μs/i) -     81.084k in   3.087631s
                           content_type spoof cold    308.017 (± 6.2%) i/s    (3.25 ms/i) -    930.000 in   3.019313s
                           content_type spoof warm     35.234k (± 2.9%) i/s   (28.38 μs/i) -    107.097k in   3.039560s
                       processable_file/image cold    133.794 (± 6.0%) i/s    (7.47 ms/i) -    403.000 in   3.012089s
                       processable_file/image warm     45.232k (± 2.9%) i/s   (22.11 μs/i) -    137.970k in   3.050258s
     multi same keys cold (aspect_ratio+dimension)    133.655 (± 6.0%) i/s    (7.48 ms/i) -    403.000 in   3.015232s
                              multi same keys warm    138.737k (± 2.2%) i/s    (7.21 μs/i) -    417.540k in   3.009576s
multi different keys cold (dimension+content_type)     36.854 (± 2.7%) i/s   (27.13 ms/i) -    111.000 in   3.011883s
                         multi different keys warm    138.732k (± 2.5%) i/s    (7.21 μs/i) -    422.871k in   3.048105s

Comparison:
                              multi same keys warm:   138737.2 i/s
                         multi different keys warm:   138732.4 i/s - same-ish: difference falls within error
                       processable_file/image warm:    45232.2 i/s - 3.07x  slower
                               duration/audio warm:    38560.0 i/s - 3.60x  slower
                              dimension/image warm:    35522.6 i/s - 3.91x  slower
                           content_type spoof warm:    35234.4 i/s - 3.94x  slower
                                    pages/pdf warm:    26260.9 i/s - 5.28x  slower
                           content_type spoof cold:      308.0 i/s - 450.42x  slower
                       processable_file/image cold:      133.8 i/s - 1036.94x  slower
     multi same keys cold (aspect_ratio+dimension):      133.7 i/s - 1038.03x  slower
                              dimension/image cold:      132.9 i/s - 1044.18x  slower
                                    pages/pdf cold:       70.3 i/s - 1974.44x  slower
                               duration/audio cold:       42.6 i/s - 3253.05x  slower
multi different keys cold (dimension+content_type):       36.9 i/s - 3764.51x  slower
```

---

## metadata_validators — IMAGE_PROCESSOR=vips (PostgreSQL)

```
========================================================================
active_storage_validations benchmarks
ruby:            ruby 4.0.10 (2026-11-19 revision a704b7cd95) +PRISM [arm64-darwin25]
rails:           8.1.4.1
IMAGE_PROCESSOR: vips
database:        PostgreSQL 17.11 (Homebrew)
BUNDLE_GEMFILE:  (default Gemfile)
host:            Darwin arm64
vips:            vips-8.18.7
ffmpeg:          ffmpeg version 9.0.2
pdfinfo:         pdfinfo version 26.10.0
file:            file-5.41
identify:        ImageMagick 7.1.2-34
time:            2026-11-26T11:14:22Z
========================================================================

ruby 4.0.10 (2026-11-19 revision a704b7cd95) +PRISM [arm64-darwin25]
Calculating -------------------------------------
                              dimension/image cold      2.601k (± 3.7%) i/s  (384.48 μs/i) -      7.980k in   3.068162s
                              dimension/image warm     37.808k (± 1.0%) i/s   (26.45 μs/i) -    115.360k in   3.051202s
                               duration/audio cold     42.739 (± 4.7%) i/s   (23.40 ms/i) -    132.000 in   3.088513s
                               duration/audio warm     42.045k (± 1.6%) i/s   (23.78 μs/i) -    126.630k in   3.011794s
                                    pages/pdf cold     64.755 (±12.4%) i/s   (15.44 ms/i) -    198.000 in   3.057686s
                                    pages/pdf warm     26.195k (± 5.6%) i/s   (38.17 μs/i) -     79.750k in   3.044451s
                           content_type spoof cold    271.052 (± 4.8%) i/s    (3.69 ms/i) -    841.000 in   3.102727s
                           content_type spoof warm     36.771k (± 2.0%) i/s   (27.20 μs/i) -    111.012k in   3.019006s
                       processable_file/image cold      2.619k (± 5.0%) i/s  (381.77 μs/i) -      7.859k in   3.000334s
                       processable_file/image warm     48.494k (± 0.9%) i/s   (20.62 μs/i) -    149.203k in   3.076706s
     multi same keys cold (aspect_ratio+dimension)      2.354k (± 5.2%) i/s  (424.84 μs/i) -      7.174k in   3.047800s
                              multi same keys warm    128.377k (±10.8%) i/s    (7.79 μs/i) -    396.603k in   3.089367s
multi different keys cold (dimension+content_type)     34.043 (± 5.9%) i/s   (29.37 ms/i) -    105.000 in   3.084342s
                         multi different keys warm    135.324k (± 9.6%) i/s    (7.39 μs/i) -    418.292k in   3.091041s

Comparison:
                         multi different keys warm:   135324.0 i/s
                              multi same keys warm:   128376.8 i/s - same-ish: difference falls within error
                       processable_file/image warm:    48494.4 i/s - 2.79x  slower
                               duration/audio warm:    42044.7 i/s - 3.22x  slower
                              dimension/image warm:    37808.1 i/s - 3.58x  slower
                           content_type spoof warm:    36771.0 i/s - 3.68x  slower
                                    pages/pdf warm:    26195.2 i/s - 5.17x  slower
                       processable_file/image cold:     2619.4 i/s - 51.66x  slower
                              dimension/image cold:     2600.9 i/s - 52.03x  slower
     multi same keys cold (aspect_ratio+dimension):     2353.8 i/s - 57.49x  slower
                           content_type spoof cold:      271.1 i/s - 499.25x  slower
                                    pages/pdf cold:       64.8 i/s - 2089.79x  slower
                               duration/audio cold:       42.7 i/s - 3166.29x  slower
multi different keys cold (dimension+content_type):       34.0 i/s - 3975.10x  slower
```

---

## metadata_validators — IMAGE_PROCESSOR=mini_magick (PostgreSQL)

```
========================================================================
active_storage_validations benchmarks
ruby:            ruby 4.0.10 (2026-11-19 revision a704b7cd95) +PRISM [arm64-darwin25]
rails:           8.1.4.1
IMAGE_PROCESSOR: mini_magick
database:        PostgreSQL 17.11 (Homebrew)
BUNDLE_GEMFILE:  (default Gemfile)
host:            Darwin arm64
vips:            vips-8.18.7
ffmpeg:          ffmpeg version 9.0.2
pdfinfo:         pdfinfo version 26.10.0
file:            file-5.41
identify:        ImageMagick 7.1.2-34
time:            2026-11-26T11:17:17Z
========================================================================

ruby 4.0.10 (2026-11-19 revision a704b7cd95) +PRISM [arm64-darwin25]
Calculating -------------------------------------
                              dimension/image cold    136.302 (± 6.6%) i/s    (7.34 ms/i) -    410.000 in   3.008028s
                              dimension/image warm     35.912k (± 3.3%) i/s   (27.85 μs/i) -    107.877k in   3.003926s
                               duration/audio cold     44.763 (± 4.5%) i/s   (22.34 ms/i) -    136.000 in   3.038222s
                               duration/audio warm     39.270k (± 3.3%) i/s   (25.46 μs/i) -    117.955k in   3.003664s
                                    pages/pdf cold     72.289 (± 6.9%) i/s   (13.83 ms/i) -    222.000 in   3.071002s
                                    pages/pdf warm     26.126k (± 3.4%) i/s   (38.28 μs/i) -     79.205k in   3.031622s
                           content_type spoof cold    321.752 (± 8.1%) i/s    (3.11 ms/i) -    984.000 in   3.058256s
                           content_type spoof warm     36.236k (± 2.9%) i/s   (27.60 μs/i) -    109.306k in   3.016504s
                       processable_file/image cold    137.081 (± 6.6%) i/s    (7.29 ms/i) -    420.000 in   3.063889s
                       processable_file/image warm     45.412k (± 2.6%) i/s   (22.02 μs/i) -    137.310k in   3.023661s
     multi same keys cold (aspect_ratio+dimension)    119.948 (± 8.3%) i/s    (8.34 ms/i) -    364.000 in   3.034647s
                              multi same keys warm    138.395k (± 2.1%) i/s    (7.23 μs/i) -    426.060k in   3.078590s
multi different keys cold (dimension+content_type)     38.629 (± 5.2%) i/s   (25.89 ms/i) -    116.000 in   3.002890s
                         multi different keys warm    138.143k (± 2.9%) i/s    (7.24 μs/i) -    415.657k in   3.008891s

Comparison:
                              multi same keys warm:   138394.5 i/s
                         multi different keys warm:   138142.9 i/s - same-ish: difference falls within error
                       processable_file/image warm:    45411.8 i/s - 3.05x  slower
                               duration/audio warm:    39270.4 i/s - 3.52x  slower
                           content_type spoof warm:    36236.0 i/s - 3.82x  slower
                              dimension/image warm:    35912.0 i/s - 3.85x  slower
                                    pages/pdf warm:    26126.3 i/s - 5.30x  slower
                           content_type spoof cold:      321.8 i/s - 430.13x  slower
                       processable_file/image cold:      137.1 i/s - 1009.58x  slower
                              dimension/image cold:      136.3 i/s - 1015.35x  slower
     multi same keys cold (aspect_ratio+dimension):      119.9 i/s - 1153.79x  slower
                                    pages/pdf cold:       72.3 i/s - 1914.46x  slower
                               duration/audio cold:       44.8 i/s - 3091.72x  slower
multi different keys cold (dimension+content_type):       38.6 i/s - 3582.62x  slower
```

---

## image_processors — vips vs mini_magick

Same-process head-to-head (`benchmark/image_processors.rb`). Cold image metadata validation only; processor switched via `ActiveStorage.variant_processor` per report.

**Summary (this machine):** libvips is about **20× faster** than MiniMagick for cold `dimension` / `processable_file` / `aspect_ratio` analysis (≈20.4×–24.4× depending on the report). The previous machine measured about 8×: the ratio depends on the machine and the ImageMagick build, libvips is faster on both.

```
========================================================================
active_storage_validations benchmarks
ruby:            ruby 4.0.10 (2026-11-19 revision a704b7cd95) +PRISM [arm64-darwin25]
rails:           8.1.4.1
IMAGE_PROCESSOR: vips
database:        SQLite 3.54.1
BUNDLE_GEMFILE:  (default Gemfile)
host:            Darwin arm64
vips:            vips-8.18.7
ffmpeg:          ffmpeg version 9.0.2
pdfinfo:         pdfinfo version 26.10.0
file:            file-5.41
identify:        ImageMagick 7.1.2-34
time:            2026-11-26T11:18:14Z
========================================================================

Note: IMAGE_PROCESSOR env is ignored here; each report sets the processor explicitly.

ruby 4.0.10 (2026-11-19 revision a704b7cd95) +PRISM [arm64-darwin25]
Calculating -------------------------------------
              dimension/image cold (vips)      2.739k (± 5.9%) i/s  (365.04 μs/i) -      8.236k in   3.006448s
       dimension/image cold (mini_magick)    137.526 (± 7.3%) i/s    (7.27 ms/i) -    420.000 in   3.053976s
       processable_file/image cold (vips)      2.657k (± 9.1%) i/s  (376.32 μs/i) -      8.204k in   3.087358s
processable_file/image cold (mini_magick)    114.942 (± 9.6%) i/s    (8.70 ms/i) -    350.000 in   3.045022s
           aspect_ratio/image cold (vips)      2.807k (± 4.7%) i/s  (356.31 μs/i) -      8.642k in   3.079190s
    aspect_ratio/image cold (mini_magick)    136.747 (± 6.6%) i/s    (7.31 ms/i) -    420.000 in   3.071371s
              multi same keys cold (vips)      2.492k (± 5.9%) i/s  (401.34 μs/i) -      7.504k in   3.011651s
       multi same keys cold (mini_magick)    122.577 (±11.4%) i/s    (8.16 ms/i) -    378.000 in   3.083779s

Comparison:
           aspect_ratio/image cold (vips):     2806.6 i/s
              dimension/image cold (vips):     2739.4 i/s - same-ish: difference falls within error
       processable_file/image cold (vips):     2657.3 i/s - same-ish: difference falls within error
              multi same keys cold (vips):     2491.7 i/s - 1.13x  slower
       dimension/image cold (mini_magick):      137.5 i/s - 20.41x  slower
    aspect_ratio/image cold (mini_magick):      136.7 i/s - 20.52x  slower
       multi same keys cold (mini_magick):      122.6 i/s - 22.90x  slower
processable_file/image cold (mini_magick):      114.9 i/s - 24.42x  slower
```
