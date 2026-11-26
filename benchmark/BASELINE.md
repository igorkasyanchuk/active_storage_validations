# Performance baseline

Checked-in snapshot of `benchmark/` output. Update when landing analyzer / metadata-validator changes, or periodically.

How to refresh: see [README.md](README.md#updating-the-baseline).

**Machine:** Apple Silicon MacBook Pro (`Darwin arm64`), 2026-11-26  
**Ruby / Rails:** 4.0.10 / 8.1.4.1 (default Gemfile)  
**BENCH_TIME / BENCH_WARMUP:** 3 / 1

The previous snapshot (2026-08-02) ran on another machine with Ruby 3.4.9, so compare against it only roughly.

**Database:** the SQLite sections run the dummy app's default database, in process. The PostgreSQL sections run the same suite against a local PostgreSQL 17 over TCP (`DATABASE_URL`): apps mostly run PostgreSQL, where each query is a round trip, larger still across a network.

Since the previous snapshot, warm validations (cached `asv_*` metadata) no longer query `active_storage_attachments`. Before → after that change, on this machine (vips; same for mini_magick):

| Report | SQLite | PostgreSQL (localhost) |
|---|---|---|
| `dimension/image warm` | 211 µs → 26 µs | 337 µs → 27 µs |
| `multi same keys warm` | 685 µs → 6.9 µs | 1.11 ms → 6.7 µs |
| `dimension/image cold` | 577 µs → 452 µs | 700 µs → 513 µs |

---

## require

```
ruby: ruby 4.0.10 (2026-11-19 revision a704b7cd95) +PRISM [arm64-darwin25]
rails: 8.1.4.1 (preloaded; not included in timing)
took 10.932ms to load active_storage_validations
```

---

## metadata_validators — IMAGE_PROCESSOR=vips (SQLite)

```
========================================================================
active_storage_validations benchmarks
ruby:            ruby 4.0.10 (2026-11-19 revision a704b7cd95) +PRISM [arm64-darwin25]
rails:           8.1.4.1
IMAGE_PROCESSOR: vips
BUNDLE_GEMFILE:  (default Gemfile)
host:            Darwin arm64
vips:            vips-8.18.7
ffmpeg:          ffmpeg version 9.0.2
pdfinfo:         pdfinfo version 26.10.0
file:            file-5.41
identify:        ImageMagick 7.1.2-34
time:            2026-11-26T08:47:42Z
========================================================================

ruby 4.0.10 (2026-11-19 revision a704b7cd95) +PRISM [arm64-darwin25]
Calculating -------------------------------------
                              dimension/image cold      2.211k (± 3.0%) i/s  (452.20 μs/i) -      6.851k in   3.098038s
                              dimension/image warm     38.205k (± 2.4%) i/s   (26.17 μs/i) -    116.746k in   3.055766s
                               duration/audio cold     42.089 (± 7.1%) i/s   (23.76 ms/i) -    128.000 in   3.041180s
                               duration/audio warm     42.621k (± 2.5%) i/s   (23.46 μs/i) -    128.400k in   3.012567s
                                    pages/pdf cold     62.149 (± 6.4%) i/s   (16.09 ms/i) -    192.000 in   3.089358s
                                    pages/pdf warm     27.168k (± 4.3%) i/s   (36.81 μs/i) -     82.890k in   3.050975s
                           content_type spoof cold    227.540 (±17.1%) i/s    (4.39 ms/i) -    696.000 in   3.058799s
                           content_type spoof warm     38.016k (± 5.0%) i/s   (26.30 μs/i) -    117.060k in   3.079224s
                       processable_file/image cold      2.130k (± 6.5%) i/s  (469.39 μs/i) -      6.583k in   3.089971s
                       processable_file/image warm     47.226k (± 6.3%) i/s   (21.17 μs/i) -    142.883k in   3.025486s
     multi same keys cold (aspect_ratio+dimension)      1.901k (± 8.9%) i/s  (526.11 μs/i) -      5.921k in   3.115112s
                              multi same keys warm    145.071k (± 6.1%) i/s    (6.89 μs/i) -    447.963k in   3.087889s
multi different keys cold (dimension+content_type)     36.017 (± 5.6%) i/s   (27.76 ms/i) -    111.000 in   3.081910s
                         multi different keys warm    149.593k (± 3.3%) i/s    (6.68 μs/i) -    463.200k in   3.096402s

Comparison:
                         multi different keys warm:   149593.0 i/s
                              multi same keys warm:   145071.0 i/s - same-ish: difference falls within error
                       processable_file/image warm:    47226.5 i/s - 3.17x  slower
                               duration/audio warm:    42621.5 i/s - 3.51x  slower
                              dimension/image warm:    38205.2 i/s - 3.92x  slower
                           content_type spoof warm:    38016.1 i/s - 3.93x  slower
                                    pages/pdf warm:    27168.4 i/s - 5.51x  slower
                              dimension/image cold:     2211.4 i/s - 67.65x  slower
                       processable_file/image cold:     2130.4 i/s - 70.22x  slower
     multi same keys cold (aspect_ratio+dimension):     1900.7 i/s - 78.70x  slower
                           content_type spoof cold:      227.5 i/s - 657.44x  slower
                                    pages/pdf cold:       62.1 i/s - 2407.01x  slower
                               duration/audio cold:       42.1 i/s - 3554.21x  slower
multi different keys cold (dimension+content_type):       36.0 i/s - 4153.44x  slower
```

---

## metadata_validators — IMAGE_PROCESSOR=mini_magick (SQLite)

```
========================================================================
active_storage_validations benchmarks
ruby:            ruby 4.0.10 (2026-11-19 revision a704b7cd95) +PRISM [arm64-darwin25]
rails:           8.1.4.1
IMAGE_PROCESSOR: mini_magick
BUNDLE_GEMFILE:  (default Gemfile)
host:            Darwin arm64
vips:            vips-8.18.7
ffmpeg:          ffmpeg version 9.0.2
pdfinfo:         pdfinfo version 26.10.0
file:            file-5.41
identify:        ImageMagick 7.1.2-34
time:            2026-11-26T08:48:40Z
========================================================================

ruby 4.0.10 (2026-11-19 revision a704b7cd95) +PRISM [arm64-darwin25]
Calculating -------------------------------------
                              dimension/image cold    118.708 (±13.5%) i/s    (8.42 ms/i) -    360.000 in   3.032663s
                              dimension/image warm     37.512k (± 4.2%) i/s   (26.66 μs/i) -    112.710k in   3.004602s
                               duration/audio cold     44.795 (± 4.5%) i/s   (22.32 ms/i) -    136.000 in   3.036039s
                               duration/audio warm     42.963k (± 1.6%) i/s   (23.28 μs/i) -    131.104k in   3.051534s
                                    pages/pdf cold     73.642 (± 4.1%) i/s   (13.58 ms/i) -    225.000 in   3.055303s
                                    pages/pdf warm     28.663k (± 1.1%) i/s   (34.89 μs/i) -     86.149k in   3.005615s
                           content_type spoof cold    296.136 (± 9.1%) i/s    (3.38 ms/i) -    893.000 in   3.015502s
                           content_type spoof warm     39.438k (± 1.8%) i/s   (25.36 μs/i) -    120.785k in   3.062636s
                       processable_file/image cold    132.868 (± 6.0%) i/s    (7.53 ms/i) -    407.000 in   3.063181s
                       processable_file/image warm     49.246k (± 3.0%) i/s   (20.31 μs/i) -    148.050k in   3.006360s
     multi same keys cold (aspect_ratio+dimension)    137.325 (± 2.9%) i/s    (7.28 ms/i) -    420.000 in   3.058429s
                              multi same keys warm    156.292k (± 2.0%) i/s    (6.40 μs/i) -    478.857k in   3.063864s
multi different keys cold (dimension+content_type)     38.997 (± 2.6%) i/s   (25.64 ms/i) -    120.000 in   3.077154s
                         multi different keys warm    152.614k (± 3.0%) i/s    (6.55 μs/i) -    462.086k in   3.027814s

Comparison:
                              multi same keys warm:   156291.9 i/s
                         multi different keys warm:   152613.7 i/s - same-ish: difference falls within error
                       processable_file/image warm:    49245.6 i/s - 3.17x  slower
                               duration/audio warm:    42963.3 i/s - 3.64x  slower
                           content_type spoof warm:    39438.2 i/s - 3.96x  slower
                              dimension/image warm:    37512.5 i/s - 4.17x  slower
                                    pages/pdf warm:    28662.7 i/s - 5.45x  slower
                           content_type spoof cold:      296.1 i/s - 527.77x  slower
     multi same keys cold (aspect_ratio+dimension):      137.3 i/s - 1138.11x  slower
                       processable_file/image cold:      132.9 i/s - 1176.29x  slower
                              dimension/image cold:      118.7 i/s - 1316.61x  slower
                                    pages/pdf cold:       73.6 i/s - 2122.31x  slower
                               duration/audio cold:       44.8 i/s - 3489.03x  slower
multi different keys cold (dimension+content_type):       39.0 i/s - 4007.78x  slower
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
time:            2026-11-26T09:02:47Z
========================================================================

ruby 4.0.10 (2026-11-19 revision a704b7cd95) +PRISM [arm64-darwin25]
Calculating -------------------------------------
                              dimension/image cold      1.951k (±11.6%) i/s  (512.57 μs/i) -      5.940k in   3.044650s
                              dimension/image warm     37.411k (± 4.1%) i/s   (26.73 μs/i) -    112.233k in   3.000037s
                               duration/audio cold     43.277 (± 4.6%) i/s   (23.11 ms/i) -    132.000 in   3.050093s
                               duration/audio warm     40.532k (± 5.4%) i/s   (24.67 μs/i) -    125.136k in   3.087326s
                                    pages/pdf cold     66.517 (±10.5%) i/s   (15.03 ms/i) -    200.000 in   3.006770s
                                    pages/pdf warm     28.942k (± 1.4%) i/s   (34.55 μs/i) -     89.320k in   3.086130s
                           content_type spoof cold    297.090 (± 8.4%) i/s    (3.37 ms/i) -    903.000 in   3.039478s
                           content_type spoof warm     39.400k (± 1.2%) i/s   (25.38 μs/i) -    120.156k in   3.049622s
                       processable_file/image cold      2.277k (± 4.5%) i/s  (439.20 μs/i) -      6.864k in   3.014670s
                       processable_file/image warm     49.434k (± 2.5%) i/s   (20.23 μs/i) -    149.952k in   3.033357s
     multi same keys cold (aspect_ratio+dimension)      1.908k (±17.8%) i/s  (524.21 μs/i) -      5.772k in   3.025716s
                              multi same keys warm    148.358k (± 7.7%) i/s    (6.74 μs/i) -    454.057k in   3.060554s
multi different keys cold (dimension+content_type)     33.836 (± 5.9%) i/s   (29.55 ms/i) -    102.000 in   3.014543s
                         multi different keys warm    148.505k (± 3.4%) i/s    (6.73 μs/i) -    452.970k in   3.050197s

Comparison:
                         multi different keys warm:   148505.2 i/s
                              multi same keys warm:   148357.8 i/s - same-ish: difference falls within error
                       processable_file/image warm:    49434.3 i/s - 3.00x  slower
                               duration/audio warm:    40532.2 i/s - 3.66x  slower
                           content_type spoof warm:    39400.3 i/s - 3.77x  slower
                              dimension/image warm:    37410.5 i/s - 3.97x  slower
                                    pages/pdf warm:    28942.4 i/s - 5.13x  slower
                       processable_file/image cold:     2276.9 i/s - 65.22x  slower
                              dimension/image cold:     1951.0 i/s - 76.12x  slower
     multi same keys cold (aspect_ratio+dimension):     1907.6 i/s - 77.85x  slower
                           content_type spoof cold:      297.1 i/s - 499.87x  slower
                                    pages/pdf cold:       66.5 i/s - 2232.60x  slower
                               duration/audio cold:       43.3 i/s - 3431.47x  slower
multi different keys cold (dimension+content_type):       33.8 i/s - 4388.97x  slower
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
time:            2026-11-26T09:04:43Z
========================================================================

ruby 4.0.10 (2026-11-19 revision a704b7cd95) +PRISM [arm64-darwin25]
Calculating -------------------------------------
                              dimension/image cold    126.672 (±10.3%) i/s    (7.89 ms/i) -    387.000 in   3.055131s
                              dimension/image warm     38.435k (± 1.8%) i/s   (26.02 μs/i) -    118.944k in   3.094690s
                               duration/audio cold     44.978 (± 4.4%) i/s   (22.23 ms/i) -    136.000 in   3.023703s
                               duration/audio warm     42.153k (± 2.0%) i/s   (23.72 μs/i) -    126.930k in   3.011181s
                                    pages/pdf cold     72.463 (± 5.5%) i/s   (13.80 ms/i) -    222.000 in   3.063632s
                                    pages/pdf warm     28.161k (± 3.2%) i/s   (35.51 μs/i) -     86.100k in   3.057373s
                           content_type spoof cold    323.989 (± 4.9%) i/s    (3.09 ms/i) -    990.000 in   3.055662s
                           content_type spoof warm     39.404k (± 0.8%) i/s   (25.38 μs/i) -    121.551k in   3.084743s
                       processable_file/image cold    136.277 (± 5.1%) i/s    (7.34 ms/i) -    416.000 in   3.052612s
                       processable_file/image warm     49.403k (± 2.5%) i/s   (20.24 μs/i) -    152.954k in   3.096064s
     multi same keys cold (aspect_ratio+dimension)    139.039 (± 2.9%) i/s    (7.19 ms/i) -    429.000 in   3.085460s
                              multi same keys warm    152.369k (± 1.6%) i/s    (6.56 μs/i) -    458.790k in   3.011045s
multi different keys cold (dimension+content_type)     38.944 (± 5.1%) i/s   (25.68 ms/i) -    120.000 in   3.081373s
                         multi different keys warm    150.953k (± 2.3%) i/s    (6.62 μs/i) -    456.360k in   3.023183s

Comparison:
                              multi same keys warm:   152369.0 i/s
                         multi different keys warm:   150953.5 i/s - same-ish: difference falls within error
                       processable_file/image warm:    49402.7 i/s - 3.08x  slower
                               duration/audio warm:    42152.9 i/s - 3.61x  slower
                           content_type spoof warm:    39403.9 i/s - 3.87x  slower
                              dimension/image warm:    38434.9 i/s - 3.96x  slower
                                    pages/pdf warm:    28161.4 i/s - 5.41x  slower
                           content_type spoof cold:      324.0 i/s - 470.29x  slower
     multi same keys cold (aspect_ratio+dimension):      139.0 i/s - 1095.87x  slower
                       processable_file/image cold:      136.3 i/s - 1118.09x  slower
                              dimension/image cold:      126.7 i/s - 1202.86x  slower
                                    pages/pdf cold:       72.5 i/s - 2102.71x  slower
                               duration/audio cold:       45.0 i/s - 3387.64x  slower
multi different keys cold (dimension+content_type):       38.9 i/s - 3912.55x  slower
```

---

## image_processors — vips vs mini_magick

Same-process head-to-head (`benchmark/image_processors.rb`). Cold image metadata validation only; processor switched via `ActiveStorage.variant_processor` per report.

**Summary (this machine):** libvips is about **17× faster** than MiniMagick for cold `dimension` / `processable_file` / `aspect_ratio` analysis (≈16.7×–17.3× depending on the report). The previous machine measured about 8×: the ratio depends on the machine and the ImageMagick build, libvips is faster on both.

```
========================================================================
active_storage_validations benchmarks
ruby:            ruby 4.0.10 (2026-11-19 revision a704b7cd95) +PRISM [arm64-darwin25]
rails:           8.1.4.1
IMAGE_PROCESSOR: vips
BUNDLE_GEMFILE:  (default Gemfile)
host:            Darwin arm64
vips:            vips-8.18.7
ffmpeg:          ffmpeg version 9.0.2
pdfinfo:         pdfinfo version 26.10.0
file:            file-5.41
identify:        ImageMagick 7.1.2-34
time:            2026-11-26T08:49:38Z
========================================================================

Note: IMAGE_PROCESSOR env is ignored here; each report sets the processor explicitly.

ruby 4.0.10 (2026-11-19 revision a704b7cd95) +PRISM [arm64-darwin25]
Calculating -------------------------------------
              dimension/image cold (vips)      2.337k (± 3.5%) i/s  (427.90 μs/i) -      7.130k in   3.050956s
       dimension/image cold (mini_magick)    143.494 (± 2.1%) i/s    (6.97 ms/i) -    442.000 in   3.080265s
       processable_file/image cold (vips)      2.331k (± 6.1%) i/s  (429.05 μs/i) -      7.140k in   3.063424s
processable_file/image cold (mini_magick)    139.341 (± 4.3%) i/s    (7.18 ms/i) -    420.000 in   3.014183s
           aspect_ratio/image cold (vips)      2.412k (± 1.2%) i/s  (414.67 μs/i) -      7.409k in   3.072276s
    aspect_ratio/image cold (mini_magick)    144.650 (± 2.1%) i/s    (6.91 ms/i) -    434.000 in   3.000354s
              multi same keys cold (vips)      2.206k (± 3.2%) i/s  (453.24 μs/i) -      6.820k in   3.091094s
       multi same keys cold (mini_magick)    141.512 (± 2.1%) i/s    (7.07 ms/i) -    430.000 in   3.038611s

Comparison:
           aspect_ratio/image cold (vips):     2411.6 i/s
              dimension/image cold (vips):     2337.0 i/s - same-ish: difference falls within error
       processable_file/image cold (vips):     2330.7 i/s - same-ish: difference falls within error
              multi same keys cold (vips):     2206.3 i/s - 1.09x  slower
    aspect_ratio/image cold (mini_magick):      144.6 i/s - 16.67x  slower
       dimension/image cold (mini_magick):      143.5 i/s - 16.81x  slower
       multi same keys cold (mini_magick):      141.5 i/s - 17.04x  slower
processable_file/image cold (mini_magick):      139.3 i/s - 17.31x  slower
```
