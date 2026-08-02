# Active Storage Validations — Guide for AI Coding Agents

This is the codebase of the [active_storage_validations](https://github.com/igorkasyanchuk/active_storage_validations) gem: Active Model validators for Rails Active Storage attachments (presence, content type, size, dimensions, duration, aspect ratio, PDF pages, etc.).

It is a **gem**, not a Rails application. Tests boot a Combustion dummy app under `test/dummy/`.

## Architecture Overview

```
lib/active_storage_validations.rb          # Entry point + infer_file_field_accept config
lib/active_storage_validations/
  *_validator.rb                           # Validators (ActiveModel::EachValidator)
  base_comparison_validator.rb             # Shared comparison options (<, <=, >, >=, between, equal_to)
  shared/asv_*.rb                          # Shared concerns used by validators
  analyzer/                                # Media metadata extractors (image/video/audio/pdf/content type)
  extensors/                               # Blob metadata + Marcel helpers
  matchers/                                # Opt-in RSpec/Minitest matchers
  form_builder.rb                          # Infers HTML accept from content_type validators
  railtie.rb / engine.rb                   # Rails integration + locale loading
config/locales/*.yml                       # I18n error messages (all locales must stay in sync)
test/
  dummy/                                   # Combustion Rails app + per-validator models
  validators/                              # Validator tests + shared_examples/
  matchers/                                # Matcher tests
gemfiles/                                  # Per-Rails-version Bundler Gemfiles (not Appraisal)
docs/upgrade_to_*.md                       # Upgrade guides
```

**Key integration points** (`railtie.rb`):

- Includes `ActiveStorageValidations` into Active Record (so `validates :avatar, attached: true` resolves `AttachedValidator`)
- Prepends `FormBuilder` onto `ActionView::Helpers::FormBuilder`
- Includes `ASVBlobMetadatable` on `ActiveStorage::Blob`

**Shared concerns** (`lib/active_storage_validations/shared/`):

| Module | Role |
|--------|------|
| `ASVActiveStorageable` | Attachment presence / attached files |
| `ASVAttachable` | Loop attachables/blobs; metadata validation path |
| `ASVAnalyzable` | Pick analyzer; cache results on blob custom metadata (`asv_*`) |
| `ASVErrorable` | `add_error` with `validator_type`, `filename`, bounds |
| `ASVOptionable` | Flatten options; evaluate Proc options |
| `ASVSymbolizable` | Map validator class → error symbol (`:content_type`, …) |

**Analyzers** depend on optional system tools: ImageMagick or libvips, ffmpeg, poppler, and the UNIX `file` command (content-type spoofing).

**Matchers** are not auto-loaded. Require them explicitly:

```ruby
require "active_storage_validations/matchers"
```

## Supported Versions (v4+)

- Ruby `>= 3.3`
- Rails `>= 7.0.1` (6.1 and 7.0.0 dropped)
- See `docs/upgrade_to_4.md` and the Unreleased section of `CHANGES.md`

### FormBuilder `accept` inference (v4)

By default, `f.file_field :avatar` may render an HTML `accept` attribute derived from `content_type` validators.

- Disable globally: `ActiveStorageValidations.infer_file_field_accept = false`
- Disable per field: `f.file_field :avatar, infer_accept: false`
- Explicit `accept:` is never overridden

## Testing Commands

Default task is `rake test` (Minitest, pattern `test/**/*_test.rb`).

### Local default Gemfile

```bash
bundle install
bundle exec rake test
bundle exec rake test TEST=test/validators/size_validator_test.rb
bundle exec rubocop --parallel
```

Use `focus` from [minitest-focus](https://github.com/minitest/minitest-focus) to run a single test method.

### Multi-Rails testing via `BUNDLE_GEMFILE`

There is **no Appraisal gem**. Pin Rails with Gemfiles under `gemfiles/`:

```bash
BUNDLE_GEMFILE=gemfiles/rails_7_0_1.gemfile bundle
BUNDLE_GEMFILE=gemfiles/rails_7_1.gemfile bundle
BUNDLE_GEMFILE=gemfiles/rails_7_2.gemfile bundle
BUNDLE_GEMFILE=gemfiles/rails_8_0.gemfile bundle
BUNDLE_GEMFILE=gemfiles/rails_8_1.gemfile bundle
BUNDLE_GEMFILE=gemfiles/rails_next.gemfile bundle

BUNDLE_GEMFILE=gemfiles/rails_7_0_1.gemfile bundle exec rake test
BUNDLE_GEMFILE=gemfiles/rails_7_1.gemfile bundle exec rake test
BUNDLE_GEMFILE=gemfiles/rails_7_2.gemfile bundle exec rake test
BUNDLE_GEMFILE=gemfiles/rails_8_0.gemfile bundle exec rake test
BUNDLE_GEMFILE=gemfiles/rails_8_1.gemfile bundle exec rake test
BUNDLE_GEMFILE=gemfiles/rails_next.gemfile bundle exec rake test
```

### Image processors

CI runs both processors. Locally:

```bash
IMAGE_PROCESSOR=vips bundle exec rake test
IMAGE_PROCESSOR=mini_magick bundle exec rake test
```

`test/test_helper.rb` sets `config.active_storage.variant_processor` from `IMAGE_PROCESSOR` and disables Active Storage previewers (so CI does not need the `image_processing` gem).

## Code Conventions

- `# frozen_string_literal: true` at the top of Ruby files
- RuboCop via `rubocop-rails-omakase` (see `.rubocop.yml`); method length max 15
- Shared modules are prefixed `ASV*`
- Validators define `ERROR_TYPES` (and often `METADATA_KEYS`); add errors through `ASVErrorable#add_error`
- Comparison validators inherit `BaseComparisonValidator` — prefer extending that over duplicating option parsing
- New / changed I18n keys must be updated in **every** file under `config/locales/`
- User-facing changes: update `README.md` and add an entry under Unreleased in `CHANGES.md`
- Breaking changes: also add/update `docs/upgrade_to_X.md`

## Common Contribution Workflows

### Changing a validator

1. Implement in `lib/active_storage_validations/<name>_validator.rb`
2. Reuse `shared/asv_*.rb` and/or `BaseComparisonValidator` when possible
3. Update tests under `test/validators/` (prefer existing `shared_examples/`)
4. Update or add dummy models under `test/dummy/app/models/<validator>/`
5. If error types change, sync all locale files
6. If the public API changes, update README + CHANGES
7. Behavior or API changes almost always require updating the related matcher under `lib/active_storage_validations/matchers/` and its tests under `test/matchers/`

### Changing a matcher

1. Implement under `lib/active_storage_validations/matchers/`
2. Compose concerns from `matchers/shared/`
3. Add/update tests under `test/matchers/`
4. Matchers filter errors using `validator_type` — keep that aligned with the validator

### Changing analyzers / metadata

1. Analyzers live under `lib/active_storage_validations/analyzer/`
2. Results are cached on the blob via `ASVBlobMetadatable` as string keys `asv_*` (S3 metadata constraints)
3. Blobs are treated as immutable: once metadata keys exist, re-analysis is skipped
4. Run tests with both `IMAGE_PROCESSOR=vips` and `IMAGE_PROCESSOR=mini_magick` when touching image analysis

### Finding related code

| Looking for… | Start here |
|--------------|------------|
| Validator behavior | `lib/active_storage_validations/<name>_validator.rb` |
| Shared attachable/blob loop | `shared/asv_attachable.rb` |
| Analysis + caching | `shared/asv_analyzable.rb`, `extensors/asv_blob_metadatable.rb` |
| Error / I18n options | `shared/asv_errorable.rb`, `config/locales/en.yml` |
| Form `accept` inference | `form_builder.rb` |
| Matcher API | `matchers.rb` + `matchers/<name>_validator_matcher.rb` |
| CI matrix truth | `.github/workflows/main.yml` |
| Version constraints | `active_storage_validations.gemspec` |

## File Organization Principles

- `lib/` — production code only
- `test/` — Minitest (not RSpec for the gem suite); Combustion dummy in `test/dummy/`
- `gemfiles/` — Rails version matrix for local/CI runs
- `docs/` — upgrade guides for humans consuming the gem
- `AGENTS.md` — this file; agent-oriented contributor guidance (humans can use it too)
- Do not invent an Appraisal setup; keep using `BUNDLE_GEMFILE=`

## Documentation

| Doc | Path |
|-----|------|
| User guide | `README.md` |
| Changelog | `CHANGES.md` |
| Upgrade to 2.x / 3.x / 4.x | `docs/upgrade_to_2.md`, `docs/upgrade_to_3.md`, `docs/upgrade_to_4.md` |

## Pitfalls

- Do not reintroduce Rails `< 7.0.1` or Ruby `< 3.3` support without an explicit project decision
- Do not auto-require matchers from the main gem entrypoint
- Do not re-enable Active Storage previewers in the dummy app without adding `image_processing`
- Marcel rejects types like `image/jpg` — use `image/jpeg` (and Marcel shorthands where registered)
- Railtie must not use `after: :load_config_initializers` (stack overflow; see comment in `railtie.rb`)
- `processable_file` may reject formats with libvips untrusted loaders (e.g. SVG) when Rails sets `Vips.block_untrusted(true)`

## Read First When Contributing

1. `README.md` (Contributing section) and `docs/upgrade_to_4.md`
2. `lib/active_storage_validations.rb` + `railtie.rb`
3. A simple validator: `attached_validator.rb`
4. Comparison path: `base_comparison_validator.rb` + `size_validator.rb`
5. Shared core: `shared/asv_attachable.rb`, `shared/asv_analyzable.rb`, `shared/asv_errorable.rb`
6. `test/test_helper.rb` + one validator test and its `shared_examples/`
7. `.github/workflows/main.yml`
