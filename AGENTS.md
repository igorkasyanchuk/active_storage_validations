# Active Storage Validations — Guide for AI Coding Agents

This is the codebase of the [active_storage_validations](https://github.com/igorkasyanchuk/active_storage_validations) gem: Active Model validators for Rails Active Storage attachments (presence, content type, size, dimensions, duration, aspect ratio, PDF pages, etc.).

It is a **gem**, not a Rails application. Specs boot a Combustion dummy app under `test/dummy/`.

## Architecture Overview

```
lib/active_storage_validations.rb          # Entry point + infer_file_field_accept / command_timeout config
lib/active_storage_validations/
  *_validator.rb                           # Validators (ActiveModel::EachValidator)
  base_comparison_validator.rb             # Shared comparison options (<, <=, >, >=, between, equal_to)
  asv_attachable_adapter.rb                # Per-type wrappers for Blob / UploadedFile / Hash / File / Pathname / signed id
  shared/asv_*.rb                          # Shared concerns used by validators
  analyzer/                                # Media metadata extractors (image/video/audio/pdf)
  analyzer/content_type_analyzer/          # Spoofing sniffers: File + Magika backends
  extensors/                               # Blob metadata + Marcel helpers
  matchers/                                # Opt-in RSpec/Minitest matchers (consumer-facing)
  form_builder.rb                          # Infers HTML accept from content_type validators
  railtie.rb / engine.rb                   # Rails integration + locale loading
config/locales/*.yml                       # I18n error messages (all locales must stay in sync)
spec/                                      # RSpec suite (validators, matchers, analyzers, form_builder, integration)
test/dummy/                                # Combustion Rails app + per-validator models
gemfiles/                                  # Per-Rails-version Bundler Gemfiles (not Appraisal)
benchmark/                                 # Optional ips / require suite (not shipped in the gem)
docs/upgrade_to_*.md                       # Upgrade guides
```

**Key integration points** (`railtie.rb` / `engine.rb`):

- `Engine` registers the gem so `config/locales/*.yml` is on the I18n load path
- `Railtie` holds the initializers:
  - Includes `ActiveStorageValidations` into Active Record (so `validates :avatar, attached: true` resolves `AttachedValidator`)
  - Prepends `FormBuilder` onto `ActionView::Helpers::FormBuilder`
  - Includes `ASVBlobMetadatable` on `ActiveStorage::Blob`

**Shared concerns** (`lib/active_storage_validations/shared/`):

| Module | Role |
|--------|------|
| `ASVActiveStorageable` | Attachment presence / attached files |
| `ASVAttachable` | Loop attachables/blobs; metadata validation path |
| `ASVAnalyzable` | Pick analyzer; cache results on blob custom metadata (`asv_*`) |
| `ASVCommandable` | Timed external commands with process-group kill (`command_timeout`) |
| `ASVErrorable` | `add_error` with `validator_type`, `filename`, bounds |
| `ASVOptionable` | Flatten options; evaluate Proc options |
| `ASVSymbolizable` | Map validator class → error symbol (`:content_type`, …) |
| `ASVLoggable` | `Rails.logger` helper used by analyzers |

**Analyzers** depend on optional system tools: ImageMagick or libvips, ffmpeg, poppler, the UNIX `file` command, and/or the [Google Magika](https://github.com/google/magika) CLI (content-type spoofing backends).

**Matchers** are not auto-loaded. Require them explicitly:

```ruby
require "active_storage_validations/matchers"
```

## Supported Versions (v4+)

- Ruby `>= 3.3` (CI also covers 3.4 and 4.0)
- Rails `>= 7.0.1` (6.1 and 7.0.0 dropped)
- See `docs/upgrade_to_4.md` and the Unreleased section of `CHANGES.md`

### FormBuilder `accept` inference (v4)

By default, `f.file_field :avatar` may render an HTML `accept` attribute derived from `content_type` validators.

- Disable globally: `ActiveStorageValidations.infer_file_field_accept = false`
- Disable per field: `f.file_field :avatar, infer_accept: false`
- Explicit `accept:` is never overridden

### Analyzer `command_timeout` (v4)

External analyzer commands (`ffprobe`, `pdfinfo`, `file`, `magika`, ImageMagick `identify`, libvips) default to a 10s deadline (`ActiveStorageValidations.command_timeout`). Override globally, via `configure`, or per validator with `timeout:`. Timeouts fail closed (existing validation errors) and emit `timeout.active_storage_validations`. Matcher: `#timeout`.

### Content-type spoofing backends (v4)

`content_type` `spoofing_protection` accepts `true` / `:file` (UNIX `file` CLI) or `:magika` (Google Magika CLI). Detected types are cached as `asv_content_type` plus `asv_content_type_backend`; switching backend re-analyzes. Legacy blobs with only `asv_content_type` are treated as the `:file` backend. Matcher: `#spoofing_protection` / `#spoofing_protection(:magika)`. Install Magika in any environment that uses `:magika` (CI installs the checksummed `cli/v1.1.0` linux tarball in `.github/workflows/main.yml`).

A missing `file` or `magika` binary raises `ActiveStorageValidations::Analyzer::ContentTypeAnalyzer::CommandLineToolNotInstalledError` (shared ancestor; both backends resolve that constant).

### Matcher `#except_on` (v4)

Matchers support `#except_on` for Rails `:except_on` (available since Rails 8.0), e.g. `validate_attached_of(:avatar).except_on(:update)`. Specs that exercise it should guard for Rails < 8.0.

### Matcher comparison bounds

`BaseComparisonValidatorMatcher` (`#less_than`, `#less_than_or_equal_to`, `#greater_than`, `#greater_than_or_equal_to`, `#between`, `#equal_to`) must probe the inclusive endpoint itself. Checking only `min + 1` / `max - 1` lets `less_than(n)` satisfy `#less_than_or_equal_to(n)`. Shared examples: `"base comparison validator matcher less_than_or_equal_to rejects less_than"`, `"… greater_than_or_equal_to rejects greater_than"`, `"… equal_to rejects looser comparisons"`.

`DimensionValidatorMatcher` probes one axis with a neutral value on the other axis derived from the declared bounds (`#neutral_dimension`). Do not reintroduce a fixed ceiling (the former 2000px default broke `width_min(2048).height_min(100)`).

`AttachedValidator` rejects `:allow_blank` / `:allow_nil`. Do not add `#allow_blank` to `validate_attached_of` or document that chain.

## Testing Commands

Default task is `rake spec` (RSpec, pattern `spec/**/*_spec.rb`).

### Local default Gemfile

The root `Gemfile` pins Rails for `bundle exec rake spec` without `BUNDLE_GEMFILE` (currently 8.1.x). Matrix pins live under `gemfiles/`.

```bash
bundle install
bundle exec rake spec
bundle exec rspec spec/validators/size_validator_spec.rb
bundle exec rubocop --parallel
```

Focus examples with `:focus` / `fit` / `fdescribe` (`filter_run_when_matching :focus` is enabled).

SimpleCov runs unless `NO_COVERAGE=1`. `minimum_coverage` is 50 locally so a targeted file still finishes; CI (`CI=true`) requires 90. The full suite is ~97%. CI uploads the coverage artifact from the Ruby 3.4 / Rails 8.1 / vips job.

### Multi-Rails testing via `BUNDLE_GEMFILE`

There is **no Appraisal gem**. Pin Rails with Gemfiles under `gemfiles/`:

```bash
BUNDLE_GEMFILE=gemfiles/rails_7_0_1.gemfile bundle
BUNDLE_GEMFILE=gemfiles/rails_7_1.gemfile bundle
BUNDLE_GEMFILE=gemfiles/rails_7_2.gemfile bundle
BUNDLE_GEMFILE=gemfiles/rails_8_0.gemfile bundle
BUNDLE_GEMFILE=gemfiles/rails_8_1.gemfile bundle
BUNDLE_GEMFILE=gemfiles/rails_next.gemfile bundle

BUNDLE_GEMFILE=gemfiles/rails_7_0_1.gemfile bundle exec rake spec
BUNDLE_GEMFILE=gemfiles/rails_7_1.gemfile bundle exec rake spec
BUNDLE_GEMFILE=gemfiles/rails_7_2.gemfile bundle exec rake spec
BUNDLE_GEMFILE=gemfiles/rails_8_0.gemfile bundle exec rake spec
BUNDLE_GEMFILE=gemfiles/rails_8_1.gemfile bundle exec rake spec
BUNDLE_GEMFILE=gemfiles/rails_next.gemfile bundle exec rake spec
```

### Image processors

CI runs both processors. Locally:

```bash
IMAGE_PROCESSOR=vips bundle exec rake spec
IMAGE_PROCESSOR=mini_magick bundle exec rake spec
```

`spec/rails_helper.rb` sets `config.active_storage.variant_processor` from `IMAGE_PROCESSOR` and disables Active Storage previewers (so CI does not need the `image_processing` gem). Unset locally: validators use MiniMagick (ASV default) and both image-analyzer unit specs run. When `IMAGE_PROCESSOR` is set, examples tagged `image_processor: :vips` / `:mini_magick` for the other processor are excluded (not pending).

Live Magika examples are gated with `magika_cli_available?` (`FixtureFiles` in `spec/support/files.rb`); most Magika unit specs stub the CLI. Fixture IOs go through `open_fixture` / `register_fixture_io` and are closed after each example.

### Benchmarks

Optional metadata-validator performance suite under `benchmark/` (`benchmark-ips`, informational CI job). Install the `:benchmark` group, then:

```bash
bundle config set --local with benchmark
bundle install
bundle exec ruby benchmark/require.rb
IMAGE_PROCESSOR=vips bundle exec ruby benchmark/metadata_validators.rb
bundle exec ruby benchmark/image_processors.rb
```

See [`benchmark/README.md`](benchmark/README.md). Update [`benchmark/BASELINE.md`](benchmark/BASELINE.md) (and the libvips recommendation in `README.md` if the ratio changes) when changing analyzer / metadata hot paths.

## Code Conventions

- `# frozen_string_literal: true` at the top of Ruby files
- RuboCop via `rubocop-rails-omakase` + `rubocop-rspec` (see `.rubocop.yml`); method length max 15
- Shared modules are prefixed `ASV*`
- Validators define `ERROR_TYPES` (and often `METADATA_KEYS`); add errors through `ASVErrorable#add_error`
- Comparison validators inherit `BaseComparisonValidator` — prefer extending that over duplicating option parsing
- New / changed I18n keys must be updated in **every** file under `config/locales/` (`spec/global/locales_spec.rb` asserts keys and English interpolation placeholders)
- User-facing changes: update `README.md` and add an entry under Unreleased in `CHANGES.md`
- Breaking changes: also add/update `docs/upgrade_to_X.md`
- Spec conventions: see `.cursor/rules/spec-*.mdc` (validators, matchers, analyzers, integration)

## Common Contribution Workflows

### Changing a validator

1. Implement in `lib/active_storage_validations/<name>_validator.rb`
2. Reuse `shared/asv_*.rb` and/or `BaseComparisonValidator` when possible
3. Update specs under `spec/validators/` (prefer existing `shared_examples/` via `it_behaves_like`)
4. Update or add dummy models under `test/dummy/app/models/<validator>/`
5. If error types change, sync all locale files
6. If the public API changes, update README + CHANGES
7. Behavior or API changes almost always require updating the related matcher under `lib/active_storage_validations/matchers/` and its specs under `spec/matchers/`

### Changing a matcher

1. Implement under `lib/active_storage_validations/matchers/`
2. Compose concerns from `matchers/shared/` (e.g. `ASVTimeoutable`, `ASVExceptOnable`, `ASVSpoofingProtectable`)
3. Add/update specs under `spec/matchers/`
4. Matchers filter errors using `validator_type` — keep that aligned with the validator
5. Comparison matchers must keep rejecting exclusive validators from inclusive chains (see Matcher comparison bounds)

### Changing analyzers / metadata

1. Analyzers live under `lib/active_storage_validations/analyzer/` (content-type sniffers under `analyzer/content_type_analyzer/`)
2. Results are cached on the blob via `ASVBlobMetadatable` as string keys `asv_*` (S3 metadata constraints). `blob.save!` runs only when the blob is already persisted; new blobs keep `asv_*` in memory until the record is saved
3. Blobs are treated as immutable: once metadata keys exist, re-analysis is skipped — except content-type spoofing, which also keys the cache on `asv_content_type_backend` (`file` vs `magika`)
4. Run specs with both `IMAGE_PROCESSOR=vips` and `IMAGE_PROCESSOR=mini_magick` when touching image analysis
5. Content-type sniffer changes usually need both `File` and `Magika` coverage under `spec/analyzers/content_type_analyzers/`
6. Missing-CLI errors must keep raising the shared `ContentTypeAnalyzer::CommandLineToolNotInstalledError`

### Finding related code

| Looking for… | Start here |
|--------------|------------|
| Validator behavior | `lib/active_storage_validations/<name>_validator.rb` |
| Shared attachable/blob loop | `shared/asv_attachable.rb` |
| Attachable type dispatch | `asv_attachable_adapter.rb` (`ASVAttachableAdapter`) |
| Analysis + caching | `shared/asv_analyzable.rb`, `extensors/asv_blob_metadatable.rb` |
| Content-type sniffers | `analyzer/content_type_analyzer/{file,magika}.rb` (`CommandLineToolNotInstalledError` on the parent) |
| Error / I18n options | `shared/asv_errorable.rb`, `config/locales/en.yml` |
| Form `accept` inference | `form_builder.rb` |
| Matcher API | `matchers.rb` + `matchers/<name>_validator_matcher.rb` |
| CI matrix truth | `.github/workflows/main.yml` |
| Dependabot | `.github/dependabot.yml` (root Gemfile + Actions; not `gemfiles/*.gemfile`) |
| Version constraints | `active_storage_validations.gemspec` |

## File Organization Principles

- `lib/` — production code only
- `spec/` — RSpec suite for the gem (validators, matchers, analyzers, form_builder, integration)
- `test/dummy/` — Combustion Rails app used by specs
- `benchmark/` — optional ips / require suite for metadata validators (not shipped in the gem)
- `gemfiles/` — Rails version matrix for local/CI runs
- `docs/` — upgrade guides for humans consuming the gem
- `AGENTS.md` — this file; agent-oriented contributor guidance (humans can use it too)
- `.cursor/rules/` — Cursor project rules (commit messages, spec conventions); referenced from this file
- `.cursor/skills/` — Agent skills (e.g. `/commit`, `update-rails-matrix`); not shipped in the gem
- `CLAUDE.md` + `.claude/` — Claude Code bridge: glob table for `.cursor/rules/`, `/commit` wrapper delegating to `.cursor/skills/commit/`, `update-rails-matrix` symlinked from `.cursor/skills/`, shared permissions; conventions stay in `.cursor/rules/` and this file
- Do not invent an Appraisal setup; keep using `BUNDLE_GEMFILE=`
- `gemfiles/rails_X_Y.gemfile` floor Rails at the latest patch (`'~> 7.2.0', '>= 7.2.4'`) so a lock refresh cannot fall back to an older release; raise the floor when bumping a lock to a new patch
- Do not reintroduce a Minitest suite for the gem itself (consumer matchers may still support Minitest)

## Documentation

| Doc | Path |
|-----|------|
| User guide | `README.md` |
| Changelog | `CHANGES.md` |
| Upgrade to 2.x / 3.x / 4.x | `docs/upgrade_to_2.md`, `docs/upgrade_to_3.md`, `docs/upgrade_to_4.md` |
| Commit messages | [`.cursor/rules/git.mdc`](.cursor/rules/git.mdc) (Conventional Commits; always apply for agents) |
| `/commit` skill | [`.cursor/skills/commit/SKILL.md`](.cursor/skills/commit/SKILL.md) (Claude Code wrapper: [`.claude/skills/commit/SKILL.md`](.claude/skills/commit/SKILL.md)) |
| Rails / Ruby test matrix updates | [`.cursor/skills/update-rails-matrix/SKILL.md`](.cursor/skills/update-rails-matrix/SKILL.md) (assess versions, bump gemfiles + CI) |
| Upstream releases to copy from | [`.cursor/skills/upstream-watch/SKILL.md`](.cursor/skills/upstream-watch/SKILL.md) (image_processing, Active Storage, Marcel, ruby-vips, mini_magick; state in `reviewed.yml`, checked after every `/commit`) |
| Claude Code bridge | [`CLAUDE.md`](CLAUDE.md) (which `.cursor/rules/` file to read per path) |
| Spec conventions | [`.cursor/rules/spec.mdc`](.cursor/rules/spec.mdc) (shared; named `subject`), plus [`spec-validators.mdc`](.cursor/rules/spec-validators.mdc), [`spec-matchers.mdc`](.cursor/rules/spec-matchers.mdc), [`spec-analyzers.mdc`](.cursor/rules/spec-analyzers.mdc), [`spec-integration.mdc`](.cursor/rules/spec-integration.mdc) |

## Git / commit messages

Use [`.cursor/rules/git.mdc`](.cursor/rules/git.mdc) for commit and PR title format. Do not infer style from `git log`. Slash `/commit` runs [`.cursor/skills/commit/SKILL.md`](.cursor/skills/commit/SKILL.md).

## Pitfalls

- Do not reintroduce Rails `< 7.0.1` or Ruby `< 3.3` support without an explicit project decision
- Do not auto-require matchers from the main gem entrypoint
- Do not re-enable Active Storage previewers in the dummy app without adding `image_processing`
- Marcel rejects types like `image/jpg` — use `image/jpeg` (and Marcel shorthands where registered)
- Marcel 2 (Rails main / 8.2+) treats `text/xml`, `audio/x-m4a`, and `audio/x-aac` as aliases (not `TYPE_EXTS` keys). `MimeType.extend` on an alias updates the canonical type, so `spoofing_protection` and `check_validity!` must consult `Marcel::TYPE_ALIASES` as well as `TYPE_PARENTS` / `TYPE_EXTS`
- Railtie must not use `after: :load_config_initializers` (stack overflow; see comment in `railtie.rb`)
- `processable_file` may reject formats with libvips untrusted loaders (e.g. SVG) when Rails sets `Vips.block_untrusted(true)`
- Preserve content-type cache backend semantics: legacy `asv_content_type` without `asv_content_type_backend` must keep hitting the `:file` cache; switching `:file` ↔ `:magika` must re-analyze
- Magika / `file` are optional system CLIs (not Ruby gems); override paths with `ActiveStorage.paths[:magika]` / `ActiveStorage.paths[:file]` when needed. Rescue missing tools via `ContentTypeAnalyzer::CommandLineToolNotInstalledError` (not a per-backend subclass)
- `AttachedValidator#check_validity!` rejects `:allow_blank` / `:allow_nil`; the attached matcher has no `#allow_blank`
- Comparison matcher inclusive chains (`#less_than_or_equal_to`, `#greater_than_or_equal_to`, `#between`) must fail when the validator is exclusive (`less_than` / `greater_than`)
- `ValidatorHelpers` filter errors with `error.options[:validator_type] == (kwargs[:validator] || validator_sym)` — keep the parentheses; `==` binds tighter than `||`
- Do not reintroduce a Minitest suite for the gem; keep consumer matcher docs for both RSpec and Minitest/shoulda
- Matcher `stub_method` uses a singleton-method wrap (not `Minitest::Mock` / `Object#stub`). Minitest 6 extracted mock to `minitest-mock`; do not reintroduce that dependency
- Do not add `ActiveStorageValidations::Attachable` (or other short names that apps use as concerns). The gem module is included into Active Record, so `include Attachable` in an app model under this namespace would resolve to the gem constant. Use the `ASV*` prefix (`spec/global/active_storage_validations_spec.rb`)
- Do not `File.open` dummy fixtures and leave the FD for GC. Use `open_fixture` / `register_fixture_io` (`FixtureFiles`); do not reintroduce an `ObjectSpace` sweep or a raised `NOFILE` rlimit to mask leaks
- Blob `asv_*` metadata is forwarded to the storage service as object metadata (S3: 2 KB, ASCII). Analyzers must only return small scalar values — never free-form hashes such as audio stream tags. Enforced over every dummy fixture by `spec/analyzers/storage_metadata_constraints_spec.rb`
- `ASVFFProbable#media_duration` (both ffprobe analyzers) is the longest of the container, audio and video track durations. Matroska / WebM report audio duration on the container only, and reading the track first let a 0.04s video track with a 30s audio track pass `less_than: 10.seconds`
- Image analyzers swap width / height for EXIF orientations 5 to 8 only (`Vips#rotated_image?` reads the `orientation` field, which also covers TIFF; `ImageMagick::QUARTER_TURN_ORIENTATIONS`). Rails' analyzers swap 2 and 4 (mirrors) and miss 5 and 7: do not copy them back. `image_700x500_rotated_90.jpg` is stored 500×700 with orientation 6; `"applies the exif orientation"` rewrites its tag to each value
- ImageMagick reports the page (`%W` / `%H`) for GIFs only (`#gif_canvas?`), which is the size libvips reports. A PNG page is a virtual canvas (vpAg / oFFs from a crop) that libvips ignores
- `VideoAnalyzer` rounds width / height (`854 * (240.0 / 427)` is 479.99…); `PdfAnalyzer::PAGE_SIZE_NUMBER` accepts pdfinfo's exponent form (`2e+06`)
- `DimensionValidatorMatcher` `#width_min` / `#height_min` / `#width_max` / `#height_max` must probe the inclusive bound itself (`min` / `max`) *and* `min + 1` / `max - 1`. Bound-only probes let exact `width: n` satisfy `#width_min(n)`; interior-only probes let exclusive min satisfy `#width_min`. Skip the `max - 1` probe when it would be `< 1` (`#width_max(1)`): a 0px probe is `media_metadata_missing`, not a bound miss
- `DurationValidator` exclusive `between:` error `:max` must use `#exclusive_range_step` (one unit of `precision:`, 1ms by default), not `end - 1` (1 second on a Duration)
- `DurationValidator` `precision:` (Integer 0..3, `DEFAULT_PRECISION = 3`) rounds the analyzed duration before comparing and in messages, after the `media_metadata_missing` check (a 0.4s file rounded to 0 is still a duration). `DurationValidatorMatcher` probes one unit of the validator's precision (`#smallest_measurement`), which is why `BaseComparisonValidatorMatcher` resolves chained bounds in `#matches?` (`#chain_bound`), once the subject is known
- `LimitValidatorMatcher` `#min(0)` must probe 0 files and require `options[:min]` to be `0` or absent (a max-only validator accepts 0 files, as 4.1 matched). Skipping all min probes lets `#min(0)` match `min: 1` under `allow_blank`
- `DimensionValidatorMatcher` `#width_min(0)` / `#height_min(0)` skip the 0px success probe (same `media_metadata_missing` trap) and require `width: { min: 0 }` / `height: { min: 0 }` or no declared `min:` on that axis (as 4.1 matched); `min: 1` must not match
- Comparison matchers `#greater_than_or_equal_to(0)` / `#equal_to(0)` on duration / pages cannot probe 0 (`media_metadata_missing`). Probe the first comparable value (1ms / 1 page) and require the validator option; size / total_size still probe 0 bytes
- `ASVBlobMetadatable` drops `asv_*` keys from a new blob in `after_initialize` (`if: :new_record?`): direct uploads (`metadata: {}` is permitted), `create_and_upload!(metadata:)` and `attach(io:, metadata:)` all go through `Blob.new`, so afterwards only the gem writes `asv_*`, and a persisted blob's cache (4.x included) is trusted. Never strip in `before_create`/`before_save`: the gem caches its analysis on new blobs in memory before the record is saved
- `ASVBlobMetadatable#remove_active_storage_validations_metadata!` must assign via `custom_metadata=` and `save!` if the blob is persisted (in-place `delete_if` does not persist; `reload` restored `asv_*`)
- `DimensionValidator` `width` / `height` `{ min:, max: }` (and `{ min: 0.. }` after flattening) must use `bound_present?`, not truthiness: `width: { max: 0 }` is a real bound
- `PdfAnalyzer` must omit non-positive `pages` / width / height (`@media["pages"].to_i` of a missing key is `0`; `Hash#compact` keeps `0` and memoizes a fake analysis)
- Analyzers create the tempfile attachables are copied to with `Analyzer#create_media_tempfile`, named with the attachable extension like `ActiveStorage::Blob#open` (ImageMagick decodes ICO / TGA from the extension). Do not go back to a bare `Tempfile.create(binmode: true)`. It yields an `Analyzer::MediaTempfile`, which creates the file on the first `#to_io` only (uploads with a usable path never need it): code that copies into it calls `#to_io` and writes to that `File` (`ASVAttachableAdapter#copy_to_tempfile`), never to the wrapper, and `create_media_tempfile` deletes it when the block returns or raises
- `ContentTypeValidator`: Proc options bypass `check_validity!`, so `authorized_content_types_from_options` re-runs `ensure_content_types_validity` on the Proc result. This includes a Proc nested in the list (`[:pdf, -> { … }]`, `proc_content_types?` looks at every entry), whose returned Array is flattened
- `ContentTypeValidator#authorized_marcel_content_type` resolves a String rule with its Marcel extension, like an upload (`declared_type` + filename): resolved from the declared type alone, an alias (`audio/x-flac`, `application/x-msaccess`) or a parameterized type (`application/dita+xml;format=map`) never equals what the upload resolves to. `invalid_content_type?` also accepts the Marcel type verbatim (parameters, capitals such as `…macroEnabled.12`)
- `ASVCommandable` must keep the `windows?` branch: `Process.spawn(pgroup: true)` and `Process.kill(sig, -pid)` raise on Windows (use `new_pgroup: true` and a direct `KILL`). The spec simulates it by stubbing `windows?`
- `ASVCommandable#run_command` reaps the child in a background waiter thread and, in `ensure`, KILLs the process group while that waiter is alive: an exception raised into the caller (`Rack::Timeout`, job shutdown) must not leave the command running or a zombie
- `VideoAnalyzer#angle` parses rotation as a rounded float and rescues unparsable values (`"90.0"` is a real-world tag). `duration` / `bit_rate` / `sample_rate` / dimensions must do the same (`ASVFFProbable#parse_float` / `#parse_integer`); ffprobe JSON must rescue `JSON::ParserError` like Magika (never raise from `valid?`)
- `image_analyzer_for` must not return `nil`: unknown processors fall through to `NullAnalyzer` so validation fails closed instead of `NoMethodError`. `:disabled` (Rails 8.1, only turns variants off) is analyzed with `DEFAULT_IMAGE_PROCESSOR` (`#image_processor`)
- `DurationValidator#format_bound_value` shows the comparison's precision (milliseconds by default) (tenths read "less than or equal to 5 seconds (current duration is 5 seconds)"); `#whole_or_milliseconds` drops `Duration#parts` float noise. Do not reintroduce rounding in messages, nor `5.seconds` for a 5.029s fixture in the dummy models
- `AspectRatioValidator#matching_ratio?` grants the one-pixel slack only to images at least x×y (4×3, 2×1 and 1×1 matched 16:9); `TotalSizeValidator` returns early when every file is marked for destruction
- `DurationValidator` humanizes values through `active_storage_validations.duration.<unit>` (`one` / `other`) and `.connectors` keys in every locale (`spec/global/locales_spec.rb` enforces parity; `ru` / `uk` / `pl` must also carry `few` / `many` for every pluralized key, see `extra_plural_forms` there). Decimal counts go through `DurationValidator::LocalizedCount` so `%{count}` follows the locale's separator while plural rules still see a number, with English defaults for other locales. Duration specs use `seconds_in_words(n)` / the `localized { … }` helper because messages are asserted in every locale
- `PdfAnalyzer` reports the first page as displayed: swap width / height when pdfinfo's `Page rot` is a quarter turn (`% 180 == 90`)
- `ASVFFProbable#video_stream` must skip `disposition.attached_pic` streams (cover art): an audio-only MP4 with a cover is not a video
- Matcher probe attachments are in-memory `StringIO`s (`Matchers::ASVAttachable#io`, `#not_processable_image`, `ContentTypeValidatorMatcher#attachment_for`) and `validate_total_size_of` attaches a Hash, not a persisted blob. Do not reintroduce `Tempfile.new` / `create_and_upload!` there
- `Matchers.mock_metadata` mocks `Analyzer.new` through `Matchers::AnalyzerMock`, prepended once on `Analyzer.singleton_class` and reading the mock from `ActiveSupport::IsolatedExecutionState`. Do not go back to a per-probe `stub_method(Analyzer, :new, …)`: overlapping threads restored each other's stub out of order and left analyzers mocked for good (`stub_method` stays for the per-matcher `io.size`)
- `Matchers.mock_metadata` mocks only the analyzers of its probe attachable (the Hash, or the IO it wraps; `MockedAnalyzer#mocks?`). Matchers validate the caller's record, so its other attachments are analyzed during probes: mocking every `Analyzer.new` cached the fake metadata on their blobs and saved it. Metadata matchers pass their `io`, never the `Attached` returned by `attach_file`
- `ASVAttachableAdapter::Base#with_path_or_copy` copies a file whose basename contains `[` (`#selector_suffix?`): libvips and ImageMagick parse a trailing `[…]` as loader options / a frame and read another file
- `ProcessableFileValidator` grants the libvips untrusted-format exemption from the file's leading bytes (`Marcel::Magic`, plus `NETPBM_HEADER` since Marcel has no rule for binary P4-P6), never from the declared content type: garbage declared as `image/bmp` passed
- `FormBuilder` must not infer `accept` from a validator whose list has an entry it cannot express (Proc, narrow Regexp): listing only the other types hides allowed files. Another validator on the attribute may still set it (files must pass every validator)
- `DimensionValidator` errors get their own values (`**errors_options, min:, max:`): mutating the shared `errors_options` leaked the width error's `min` / `max` into the height error. `validate_min_max` reports both bounds (`map`, then `all?`)
- `DimensionValidatorMatcher#axis_bounds` probes an unchained axis within the validator's declared bounds (exact, `in:`, `min` / `max`, top-level `min:` / `max:` ranges, Procs evaluated on the subject); 1000px is only the fallback when no bound exists
- `DimensionValidator` flattens `in:` with `Range#min` / `#max`, which already honors exclusive integer ranges (`400...600` rejects 600 and reports 599). Comparison validators report an exclusive `between:` end through `BaseComparisonValidator#last_included_range_end`
- `ASVAttachableAdapter` handlers hand a path to the analyzer commands only through `Base#with_path_or_copy`: a regular file identical to the io (`File.file?` + `File.identical?`, or a closed IO, whose path is all that is left), passed through `File.absolute_path` (relative `-image.png` / `clip:1.mp4` are read as an option / ffmpeg protocol; unlike `expand_path` it leaves `~$lock.png` alone). Anything else (StringIO, streaming wrappers, unlinked or anonymous Tempfile, `Rack::Test::UploadedFile` on a StringIO) is copied to the tempfile
- `AspectRatioValidator` checks Proc results like static options (`ensure_aspect_ratios_validity`): an unknown ratio returned by a Proc raises instead of rejecting every file with "must be 0:0"
- `ASVErrorable#add_error` interpolates the placeholders of a custom String `message:` that an error does not carry as blank (`#blank_custom_message_values`): `%{max}` on `media_metadata_missing` raised `I18n::MissingInterpolationArgument` on upload. Rails' `attribute` / `model` / `value` are left to Rails. `duration` / `pages` / `aspect_ratio` pass their bounds on unanalyzable-file errors
- `ASVAnalyzable#image_processor_for_transformer` (Rails 8.2+ transformer class `variant_processor`): a subclass of Rails' ImageMagick transformer is analyzed with ImageMagick, any other class with libvips
- ImageMagick `identify` must target the first frame (`path[0]`, see `ImageMagick#first_frame`); without it every frame of an animated GIF / multi-page TIFF is decoded. Escape `%` as `%%` in that path: ImageMagick reads printf patterns in a filename followed by a frame selector (`summer%20dress.png[0]`)
- `ImageMagick#parse_identify_output` ignores `%[orientation]` for a PNG without EXIF orientation: that value comes from ImageMagick's private `orNT` chunk, which libvips and browsers ignore
- `ASVFFProbable#read_media` returns `{}` for playlist formats: `#media_from_path` recognizes them from their first bytes (`PLAYLIST_HEADS`) before running ffprobe, which opens the entries while it probes (a FIFO entry hung it), and `PLAYLIST_FORMATS` (hls, dash, concat) catches what the heads miss. ffprobe reports the streams of the files a playlist names, read from the server, not the upload's. Its `#packet_duration` fallback (a second ffprobe run over the packets) only runs when neither the container nor a stream has a duration (MediaRecorder WebM)
- The `file` analyzer passes `-L`: Linux libmagic does not follow symlinks by default (`inode/symlink`), macOS does. Its spec emulates Linux with a wrapper script
- Validators that analyze each file compute their flattened options once in `validate_each` and pass them to `validate_changed_files_from_metadata(..., *validation_options)`, which forwards them to `is_valid?`. Do not call `set_flat_options(record)` from `is_valid?`: Proc options ran once per file (N+1 queries). `spec/validators/integration/proc_options_spec.rb` counts the calls
- `ASVAttachable#pending_upload_attachable` (Rails 7.1+): a second `attach` before save hands the files of the first back as new-record blobs not uploaded yet. Analyze the attachable from `attachment_changes[...].pending_uploads` instead, or the download raises `FileNotFoundError` (`attachment_missing`)
- `ASVAnalyzable#persist_asv_metadata` rescues `ActiveRecord::ReadOnlyError` / `ReadOnlyRecord` (reading role): keep the analysis in memory, never raise from `valid?`
- `ASVBlobMetadatable` reads custom metadata through `#active_storage_validations_custom_metadata`, which ignores a non-Hash `custom` (direct uploads accept `metadata: { custom: "x" }`). Do not read `metadata["custom"]` directly
- `ASVErrorable#custom_message_templates` resolves a Symbol `message:` like Rails (the Symbol replaces the error type in the i18n keys) in every `I18n.available_locales`, so the blanked placeholders cover the locale the message is rendered in later
- `ActiveStorageValidations.remove_metadata!` writes the `metadata` column with `update_column` (no blob callbacks: `touch_attachments` would touch every attached record). The rake task lives in `lib/tasks/` and is loaded by the Engine: loading it from the Railtie too would run it twice
- `ContentTypeValidator::WILDCARD_CONTENT_TYPE` (`"image/*"`) is kept as written in the authorized list (not resolved through Marcel), shown as written in messages, and expanded by `ContentTypeValidatorMatcher#probe_content_types` to every `Marcel::TYPE_EXTS` type of that media type
- `ASVMessageable#has_an_error_message_which_is_custom_message?` compares `#with_message` with the declared `message:` and the rendered `error.message` (`ActiveModel::Error` objects, not `errors.details`); a Regexp matches either. Matchers only count the errors in a validator's `ERROR_TYPES`, so every error a validator can add (`attachment_missing` included) must be listed there (`"reports attachment_missing"` checks it)
- `ASVValidatable#validate` prepends `NonStrictProbeErrors` onto `ActiveModel::Errors` once and flags the probe: `strict: true` validators then add their error during matcher probes instead of raising. The flag is restored after each probe, so the app's own validations still raise
- `AspectRatioValidatorMatcher` probes a named ratio with several shapes (`PORTRAIT_PROBES`, `A_SERIES_PROBES`): allowed means every probe passes, rejected means none does. One probe let `allowing(:portrait)` match `:is_1_2`
- `Analyzer#media` memoizes with `defined?(@media)`, not `@media ||=`: a `nil` result (failed command) ran the command again on the next call, and `ASVFFProbable#read_media` reads it twice
- A media analysis that produced nothing is not cached on the blob (a later validation retries it), but is shared between the metadata validators of one validation: `ASVAnalyzable#share_failed_analysis` marks the error the validator just added (`FailedAnalysis` in an instance variable of the `ActiveModel::Error`, so it is cleared with the errors by the next `valid?`) and `#metadata_for_validation` skips the analysis when it finds that mark for the same blob and the same `timeout:`. Do not move the mark to the blob or the record (it would outlive the validation, see `"analyzes the file again"` in `spec/validators/integration/failed_analysis_spec.rb`), and do not mark `attachment_missing` errors (the next validator would report `media_metadata_missing`). Validators with their own loop (`DurationValidator`) must call both methods
- Named and A-series `aspect_ratio` labels go through `active_storage_validations.aspect_ratios.*` (every locale; `spec/global/locales_spec.rb` enforces parity). Validator specs assert them with `localized { aspect_ratio_name(:square) }`

## Read First When Contributing

1. `README.md` (Contributing section) and `docs/upgrade_to_4.md`
2. `.cursor/rules/git.mdc` (commit / PR title format)
3. `lib/active_storage_validations.rb` + `railtie.rb`
4. A simple validator: `attached_validator.rb`
5. Comparison path: `base_comparison_validator.rb` + `size_validator.rb`
6. Shared core: `asv_attachable_adapter.rb`, `shared/asv_attachable.rb`, `shared/asv_analyzable.rb`, `shared/asv_errorable.rb`
7. Spoofing / sniffers: `content_type_validator.rb` + `analyzer/content_type_analyzer/`
8. `spec/rails_helper.rb` + one validator spec and its `shared_examples/`
9. `.github/workflows/main.yml`
