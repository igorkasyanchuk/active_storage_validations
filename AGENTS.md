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

`content_type` `spoofing_protection` accepts `true` / `:file` (UNIX `file` CLI) or `:magika` (Google Magika CLI). Detected types are cached as `asv_content_type` plus `asv_content_type_backend`; switching backend re-analyzes. Legacy blobs with only `asv_content_type` are treated as the `:file` backend. Matcher: `#spoofing_protection` / `#spoofing_protection(:magika)`. Install Magika in any environment that uses `:magika` (CI pins the CLI to `cli/v1.1.0` in `.github/workflows/main.yml`).

A missing `file` or `magika` binary raises `ActiveStorageValidations::Analyzer::ContentTypeAnalyzer::CommandLineToolNotInstalledError` (shared ancestor; both backends resolve that constant).

### Matcher `#except_on` (v4)

Matchers support `#except_on` for Rails `:except_on` (available since Rails 8.0), e.g. `validate_attached_of(:avatar).except_on(:update)`. Specs that exercise it should guard for Rails < 8.0.

### Matcher comparison bounds

`BaseComparisonValidatorMatcher` (`#less_than`, `#less_than_or_equal_to`, `#greater_than`, `#greater_than_or_equal_to`, `#between`, `#equal_to`) must probe the inclusive endpoint itself. Checking only `min + 1` / `max - 1` lets `less_than(n)` satisfy `#less_than_or_equal_to(n)`. Shared examples: `"base comparison validator matcher less_than_or_equal_to rejects less_than"`, `"… greater_than_or_equal_to rejects greater_than"`, `"… equal_to rejects looser comparisons"`.

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

SimpleCov runs unless `NO_COVERAGE=1`. `minimum_coverage` is 50 (`spec/spec_helper.rb`) so a targeted file still finishes; the full suite is ~97%. CI uploads the coverage artifact from the Ruby 3.4 / Rails 8.1 / vips job.

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

Live Magika examples are gated with `magika_cli_available?` (`spec/support/files.rb`); most Magika unit specs stub the CLI.

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
2. Results are cached on the blob via `ASVBlobMetadatable` as string keys `asv_*` (S3 metadata constraints)
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
- `.cursor/skills/` — Cursor Agent skills (e.g. `/commit`); not shipped in the gem
- Do not invent an Appraisal setup; keep using `BUNDLE_GEMFILE=`
- Do not reintroduce a Minitest suite for the gem itself (consumer matchers may still support Minitest)

## Documentation

| Doc | Path |
|-----|------|
| User guide | `README.md` |
| Changelog | `CHANGES.md` |
| Upgrade to 2.x / 3.x / 4.x | `docs/upgrade_to_2.md`, `docs/upgrade_to_3.md`, `docs/upgrade_to_4.md` |
| Commit messages | [`.cursor/rules/git.mdc`](.cursor/rules/git.mdc) (Conventional Commits; always apply for agents) |
| `/commit` skill | [`.cursor/skills/commit/SKILL.md`](.cursor/skills/commit/SKILL.md) |
| Spec conventions | [`.cursor/rules/spec.mdc`](.cursor/rules/spec.mdc) (shared; named `subject`), plus [`spec-validators.mdc`](.cursor/rules/spec-validators.mdc), [`spec-matchers.mdc`](.cursor/rules/spec-matchers.mdc), [`spec-analyzers.mdc`](.cursor/rules/spec-analyzers.mdc), [`spec-integration.mdc`](.cursor/rules/spec-integration.mdc) |

## Git / commit messages

Use [`.cursor/rules/git.mdc`](.cursor/rules/git.mdc) for commit and PR title format. Do not infer style from `git log`. Slash `/commit` runs [`.cursor/skills/commit/SKILL.md`](.cursor/skills/commit/SKILL.md).

## Pitfalls

- Do not reintroduce Rails `< 7.0.1` or Ruby `< 3.3` support without an explicit project decision
- Do not auto-require matchers from the main gem entrypoint
- Do not re-enable Active Storage previewers in the dummy app without adding `image_processing`
- Marcel rejects types like `image/jpg` — use `image/jpeg` (and Marcel shorthands where registered)
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
