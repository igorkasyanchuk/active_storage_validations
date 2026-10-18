# Unreleased

# Released
- 5.0.0
  - Same Ruby (`>= 3.3`) / Rails (`>= 7.0.1`) as 4.x; `spoofing_protection` with the default `:file` backend now needs `file` >= 5.26 (2016). No validator, option, matcher, or I18n key was renamed or removed. **Most apps bump the gem and keep the same code**: the breaking changes below are edge cases, each saying who is affected. See the [upgrade guide](docs/upgrade_to_5.md) for the one-minute checklist
  - **BREAKING** (edge cases)
    - **Security: the `asv_*` metadata cache is signed**. Clients can write a blob's custom metadata (Rails' direct upload endpoint permits `metadata: {}` and only strips `analyzed` / `identified` / `composed`, and the signed id it returns can be attached to any attachment param), so a forged `asv_width`, `asv_duration` or `asv_content_type` skipped the analysis: an oversized image passed `dimension`, an undecodable file passed `processable_file`, a spoofed file passed `spoofing_protection`. The gem now stores `asv_signature`, an HMAC of the blob checksum and its `asv_*` values keyed from `secret_key_base`, and ignores values it did not sign for that content. Blobs analyzed by 4.x (or before a `secret_key_base` rotation) are analyzed again once, the next time a validator reads them. [Details](docs/upgrade_to_5.md#the-asv_-metadata-cache-is-signed)
    - **Validator options are no longer forwarded to `errors.add`**, like Rails' built-in validators (`LengthValidator::RESERVED_OPTIONS`). Affects custom `message:` strings or locale overrides interpolating a raw option (`%{less_than}`, …), which now raise `I18n::MissingInterpolationArgument`, and code reading those options from `errors.details`. Use the documented values (`%{max}`, `%{min}`, `%{exact}`, …), which are unchanged. `errors.details` no longer carries check options or configuration (`timeout:`, `spoofing_protection:`), so it stays JSON-serializable with Proc / Range options. [Details](docs/upgrade_to_5.md#validator-options-are-no-longer-forwarded-to-errorsadd)
    - **Endless / beginless ranges raise at boot**: `size` / `total_size` / `duration` / `pages` `between: 1.kilobyte..` and `dimension` `width` / `height` `{ in: 100.. }` (or `{ min: 100.. }` / `{ max: ..800 }`). They used to load, then raise `RangeError` on the first invalid file. Use a single-bound option (`greater_than_or_equal_to:`, `{ min: }`, …). Proc ranges are not checked at boot and no longer raise. [Details](docs/upgrade_to_5.md#unbounded-between--dimension-ranges)
    - **Empty `content_type` / `aspect_ratio` lists fail closed**: `with: []` / `in: []` raises at boot, and a Proc returning `[]` rejects the file. Both used to accept every file. [Details](docs/upgrade_to_5.md#empty-content_type--aspect_ratio-lists-fail-closed)
    - **Malformed `dimension` options raise at boot**: a `width` / `height` Hash with no known key (`{ minimum: 1000 }`, `{}`) used to validate nothing and accept every file; a bare Range (`width: 100..200`) rejected every file as an exact width; `{ min: 100..200 }` inside `width` / `height`, `nil` values, `:in` combined with `:min` / `:max`, and top-level `min:` / `max:` combined with `width` / `height` (which silently dropped a bound, or raised `NoMethodError`) now raise `ArgumentError`. Proc results are not checked at boot. [Details](docs/upgrade_to_5.md#malformed-dimension-options-raise-at-boot)
    - **Invalid comparison, `limit`, `with_audio` and `timeout` options raise at boot**:
      - `size` / `total_size` / `duration` / `pages`: a bound that is not a non-negative number (`less_than: "2MB"` used to raise from `valid?`, `less_than: -1` rejected every file), or a reversed / empty `between:` range (`5..1`, `3...3`, which rejected every file)
      - `limit`: a negative `min:` / `max:` (`max: -1` rejected every record, even without files)
      - `with_audio`: a `with:` other than `true` / `false` (`with: "no"` behaved as `true`)
      - `timeout:` / `ActiveStorageValidations.command_timeout`: anything but a positive number or `nil` (`0` failed every file, a Proc raised `NoMethodError` from `valid?`)
      - Values returned by Procs are checked when evaluated and raise the same `ArgumentError` when they have the wrong type (a `with_audio` Proc returning `nil` used to reject silent files as `audio_present`). A comparison or `limit` Proc may still return a negative number, a Float / BigDecimal or a reversed range (a quota already exceeded): the file fails with the usual error, as in 4.x. [Details](docs/upgrade_to_5.md#invalid-options-raise)
    - **A comparison Proc returning `nil` sets no bound**: `size: { less_than: ->(record) { record.plan.max_size } }` returning `nil` used to reject every file with a blank bound in the message ("must be less than  (current size is 1 KB)"); it now accepts it, like `limit` already did. [Details](docs/upgrade_to_5.md#comparison-procs-returning-nil-set-no-bound)
    - **Inexact `aspect_ratio` values raise at boot** (`:is_16_9_extra`, `:is_16_9square`). `ASPECT_RATIO_REGEX` is now anchored; those values used to load and be validated as `16:9`. [Details](docs/upgrade_to_5.md#aspect_ratio-options-are-validated-strictly)
    - **`with_audio` fails closed on unanalyzable files**: when `ffprobe` is missing, times out, or cannot read the file, both `with: true` and `with: false` now add `media_metadata_missing`. `with: false` used to accept those files, `with: true` reported `audio_missing`. Images and PDFs still count as having no audio track. [Details](docs/upgrade_to_5.md#with_audio--with-false--fails-closed)
    - **`spoofing_protection: true` / `:file` needs `file` >= 5.26** (2016; every maintained Linux distribution and macOS ship it). The backend now runs `file -E -P bytes=1048576` (see **CHANGED**); with an older `file` (CentOS 7, Amazon Linux 2) every spoofing check fails with `content_type_analysis_failed`. Upgrade `file`, point `ActiveStorage.paths[:file]` at a newer binary, or use `spoofing_protection: :magika`. Check with `file --version`. [Details](docs/upgrade_to_5.md#file-526-for-spoofing_protection)
    - **Matchers fail on an attribute without a validator of their type**: `validate_size_of(:avatar)` (and the `content_type`, `dimension`, `limit`, `aspect_ratio`, … matchers) used to pass when `:avatar` had no such validator and the chain probed nothing, so `is_expected.not_to validate_size_of(:avatar)` always failed. Matchers also probe a copy of the subject: they no longer save probe attachments on a persisted record, nor drop the record's own pending attachments. Only specs relying on those side effects are affected. [Details](docs/upgrade_to_5.md#matchers-require-a-validator-and-probe-a-copy)
    - **`spoofing_protection` rejects sibling types**: the declared and detected types used to match when they merely shared a Marcel parent, so a PHP script uploaded as `data.csv` passed `content_type: { with: :csv, spoofing_protection: true }` (`text/x-php` and `text/csv` are both `text/plain` children), like a JAR as a DOCX (both `application/zip`) or an Excel file as Word. They now match only when one is the other, a Marcel alias of it, or an ancestor / descendant of it (`text/plain` for a CSV, `application/zip` for a DOCX or an XLSM). The audio / video flavors of the Ogg and WebM containers still match each other (Magika reports an Ogg video as `audio/ogg`; a `MediaRecorder` `audio/webm` recording, which both sniffers report as `video/webm`, now passes a direct upload). A real file sniffed as a sibling of its declared type is now `content_type_spoofed`. [Details](docs/upgrade_to_5.md#spoofing_protection-rejects-sibling-types)
    - **New `content_type_analysis_failed` error** (all bundled locales, same values as `content_type_invalid`) when the spoofing analysis itself produced nothing (`file` / `magika` timed out, unsupported file, invalid CLI output). It used to be reported as `content_type_spoofed`. The file is still rejected; only code matching `:content_type_spoofed` or overriding that locale key is affected. [Details](docs/upgrade_to_5.md#content_type_analysis_failed-error)
  - **ADDED**
    - Localize `duration` error values (`%{duration}`, `%{min}`, `%{max}`, `%{exact}`) through new `active_storage_validations.duration` I18n keys in every bundled locale (`1 minute et 30 secondes` in French) instead of the English-only `ActiveSupport::Duration#inspect`. Locales the gem does not ship fall back to English. [Details](docs/upgrade_to_5.md#localized-duration-values)
  - **CHANGED**
    - Matcher `#description` lists the chained qualifiers (`validate file size of :avatar, less than 2 MB, on :update`), so RSpec one-liners and shoulda-context test names tell two chains on one attribute apart. Failure messages list only the probes with an unexpected outcome, including probes the validator accepted whereas it should have rejected them; `validate_aspect_ratio_of`, `validate_attached_of`, `validate_processable_file_of` and `validate_with_audio_of` failure messages now say which probe failed
    - When `ActiveStorage.variant_processor` is unset, image analyzers fall back to `:vips` instead of `:mini_magick` (README recommendation, Rails 7.1+ default). A booted Rails app still uses the processor Rails set. Set `config.active_storage.variant_processor = :mini_magick` to keep ImageMagick
    - `content_type` Proc results are checked at validation time with the same `ArgumentError` static options get at boot. A Proc returning an unsupported type (e.g. `"image/jpg"`) used to reject every file with a blank message ("authorized content type is )"). Types Marcel knows no extension for are now rendered as-is in `*_human_content_type(s)`
    - `aspect_ratio` Proc results (top-level or nested in an `in:` list) are checked the same way. A Proc returning an unknown ratio (`:sqaure`, `"16:9"`) used to reject every file with "must be 0:0"; an Array returned by a nested Proc is flattened
    - `content_type` `spoofing_protection` with the `:file` backend downloads only the first MiB of persisted blobs, and runs `file -E -P bytes=1048576` so every attachable is sniffed on that same first MiB (recent libmagic reads up to 7 MiB by default, so an upload and the same file as a blob could get different verdicts) and a filesystem error ("cannot open …", exit status 0 without `-E`) is never taken for the detected type. Requires `file` >= 5.26 (2016). `:magika` still downloads the whole blob. [Details](docs/upgrade_to_5.md#file-526-for-spoofing_protection)
  - **FIXED** (found in review, none reported as GitHub issues; none require a code change. ♻️ = the cached result changed; blobs analyzed under 4.x carry an unsigned cache, so they are analyzed again automatically)
    - **Comparison bounds** (`size`, `total_size`, `duration`, `pages`, `limit`, `dimension`)
      - A bound of `0` is a real bound: `equal_to: 0`, `greater_than_or_equal_to: 0`, `limit: { max: 0 }` / `{ min: 0 }`, `dimension` `width` / `height` `{ max: 0 }` (or a Proc returning `0`). Those checks used to be skipped: comparison validators rejected every file, `limit` rejected records with no files, `dimension` accepted every file
      - Exclusive `dimension` `in:` ranges are honored (`400...600` no longer accepts 600)
      - Exclusive ranges report the last included value as error `:max` (`400...600` reports `599`; `duration` `2.seconds...7.seconds` uses a 1ms step instead of advertising "6 seconds")
      - `size` / `limit` / `total_size` ignore attachments marked for destruction, so nested-attributes replace flows no longer count a doomed file
      - `limit: { min: 1, max: -> { … } }` (a Proc on only one side) now loads instead of raising "You must pass integers"
    - **`duration`**
      - ♻️ No longer rounds the analyzed duration to 0.1s before comparing: a 1.96s file passes `less_than: 2.seconds`, a 2.04s file fails `less_than_or_equal_to: 2.seconds`
      - ♻️ WebM / Matroska audio (e.g. browser `MediaRecorder` Opus) is no longer rejected with `media_metadata_missing`: the audio analyzer falls back to the container duration, like the video analyzer
    - **`aspect_ratio`**
      - `is_x_y` ratios also accept a side within a pixel of the other one scaled to `x:y`, so common sizes such as 1366×768 and 854×480 pass `:is_16_9` (1366 × 9 / 16 = 768.375). Everything the 4.x rule (ratios equal to 3 decimals) accepted still passes
    - **`content_type`**
      - Marcel 2 / Rails main (8.2+): `spoofing_protection` no longer rejects `audio/aac`, `application/xml` or `audio/mp4` (`file` reports aliases such as `text/xml`, `audio/x-m4a`), and Marcel 1 canonical options such as `audio/x-aac` are still accepted
      - `spoofing_protection` compares the Marcel-resolved type (filename fallback included) against the sniffer, so a blank declared `content_type` no longer skips the check
      - A Proc nested in the list (`[:pdf, -> { … }]`) is checked at validation time like a top-level Proc, and an Array it returns is flattened. Unsupported types it returned were silently ignored, and a returned Array was dropped, so every file was rejected
    - **`dimension`**
      - A `width:` / `height:` Proc returning a frozen Hash no longer raises `FrozenError` from `valid?`, and a non-frozen one is no longer modified (the flattened `:min` / `:max` were written into it)
    - **`with_audio`**
      - `with: -> { … }` evaluates the Proc. It used to be treated as truthy, so every file failed
    - **`processable_file`**
      - ♻️ An empty media container (`ffprobe` exits 0 with zero streams) is no longer processable, nor accepted by `with_audio: { with: false }`
    - **All metadata validators** (`dimension`, `aspect_ratio`, `duration`, `pages`, `processable_file`, `with_audio`)
      - Files marked for destruction are skipped, like `size` / `limit` / `total_size` (and `content_type`). A persisted `has_one_attached` file, or an existing `has_many_attached` file when new ones are attached, used to be validated even with `_destroy`, so a form could not remove an out-of-policy file
      - No more `TypeError` when a Hash attachable's `io:` has no filesystem path (streaming wrapper, Zip entry, …): it is copied to a tempfile
      - The same copy is used, here and for `content_type` `spoofing_protection`, when an attachable's path does not hold its content: a `Rack::Test::UploadedFile` built on a `StringIO` no longer raises `NoMethodError`, a Hash `io:` Tempfile that was unlinked no longer raises `Errno::ENOENT` (or reports `file` as not installed), and an anonymous Tempfile (Ruby 3.4) is no longer analyzed as its tmp directory (`inode/directory`)
      - Relative `File` / `Pathname` attachables are expanded before reaching the analyzer commands, which read `-image.png` as an option and `clip:1.mp4` as an ffmpeg protocol and rejected valid files
      - The analyzer is picked from the declared type (case and parameters ignored), then, when it is blank or `application/octet-stream`, from the type Rails identified for the blob (magic bytes), then from the filename. A valid file declared as `application/octet-stream`, `IMAGE/PNG` or `""` (common with some clients and direct uploads) used to get no analyzer and was rejected (`file_not_processable`, `media_metadata_missing`)
      - Image validators fail closed (`media_metadata_missing`) instead of raising `NoMethodError` when `ActiveStorage.variant_processor` is `:disabled` or unknown
    - **Analyzers**
      - Windows: analyzer commands (`ffprobe`, `pdfinfo`, `file`, `magika`, `identify`) no longer raise since 4.0 (`Process.spawn(pgroup: true)` is Unix-only). On timeout the child is killed directly
      - An exception raised into the validating thread while an analyzer command runs (`Rack::Timeout`, job shutdown, …) kills the command. It used to keep running, and became a zombie process with `command_timeout = nil`
      - Blobs and other copied attachables are analyzed from a tempfile named with their extension, like `ActiveStorage::Blob#open`, so ImageMagick identifies formats without a magic number (ICO, TGA) from a blob as it does from an upload
      - `VideoAnalyzer` / `AudioAnalyzer` no longer raise from `valid?` on invalid ffprobe JSON, `N/A` numeric fields, a non-integer rotation (`"90.0"`) or a missing `side_data_list`; analysis fails closed
      - ImageMagick `identify` targets the first frame only (`path[0]`), so large animated GIFs / multi-page TIFFs no longer hit `command_timeout`
      - ♻️ `PdfAnalyzer` applies the first page's `/Rotate`: a 200×300 pt page rotated by 90° is reported as 300×200, as displayed, like rotated images and videos
      - ♻️ `VideoAnalyzer` ignores cover art (`attached_pic` streams): an audio-only MP4 with an embedded cover no longer reports the cover's dimensions and `video: true`
      - `PdfAnalyzer` no longer caches `pages: 0` (or 0-pt width / height) when `pdfinfo` omits them, so the analysis can retry and `processable_file` no longer treats `{ pages: 0 }` as a decoded file
      - Audio stream tags (ID3 / Vorbis) are no longer cached as `asv_tags`. No validator read them, and a large or non-ASCII tag hash could exceed S3's 2 KB object-metadata limit and fail the upload
      - `blob.remove_active_storage_validations_metadata!` persists the cleared cache on saved blobs (it only changed memory, so `reload` restored stale `asv_*`) and keeps non-`asv_*` custom metadata
    - **Matchers**
      - Exclusive ranges are honored by `#between`, `#width_between`, `#height_between` (`80...100` used to be read as inclusive)
      - `validate_dimensions_of` `#width_min` / `#height_min` / `#width_max` / `#height_max` probe the inclusive bound itself, so an exclusive validator no longer satisfies them
      - `validate_dimensions_of(...).width_min(n)` / `.height_min(n)` match when `n` is above 2000px and the other axis is bounded too (no more hard-coded 2000px neutral value)
      - Zero and near-zero bounds match a correct validator: `validate_limits_of(...).min(0)` (no longer passes against `min: 1`), `validate_duration_of(...).less_than(1.second)` (1ms step), `validate_duration_of` / `validate_pages_of` `#greater_than_or_equal_to(0)` / `#equal_to(0)`, `validate_dimensions_of` `#width_min(0)` / `#height_min(0)` / `#width_max(1)` / `#height_max(1)`
      - `validate_with_audio_of(...).without_audio.with_message(...)` probes a file with an audio track
      - `duration`, `pages` and `content_type` `ERROR_TYPES` include `:media_metadata_missing` / `:attachment_missing`, so matchers recognize those errors
      - `validate_processable_file_of` messages say "processable file" instead of "processable image"
      - `#except_on(:create)` matches: probes run in a context the validator does not skip (they used to validate in `:create`, so the validator never ran and every probe passed)
      - `validate_content_type_of(...).with_message(...)` detaches its probe file, which used to stay attached and corrupt the next `#allowing` / `#rejecting` probes on a `has_many_attached`
      - `#with_message` matches when several validators on the attribute share the message
      - `validate_limits_of(...).with_message(...)` without `#min` / `#max` raises an explicit `ArgumentError` instead of `NoMethodError`
      - A matcher instance reused on another subject no longer returns the previous subject's `content_type` / `aspect_ratio` result nor repeats failure message lines
      - `Matchers.mock_metadata` keeps its `Analyzer.new` mock per thread: concurrent probes (`parallelize(with: :threads)`) could restore each other's stub out of order and leave every analyzer mocked for good
  - **MISC**
    - Internals (only relevant if you monkey-patch the gem, see [upgrade guide](docs/upgrade_to_5.md#internal-api-removals))
      - Remove dead attachable helpers (`attachable_content_type_rails_like`, `attachable_io`, `rewind_attachable_io`, `supports_pathname_attachment?`, `attachable_media_type`) and the adapter `read` / `rewind`: `ASVAttachableAdapter` handlers only expose `content_type`, `filename` and `with_media_path`
      - `ASVOptionable#flatten_options` keeps only the validator check options instead of replacing every other option with `{}`
      - Replace the `define_method` block generating the `DimensionValidator` min / max helpers with plain methods
      - Matchers build probe attachments on in-memory `StringIO`s instead of never-closed `Tempfile`s, and `validate_total_size_of` no longer uploads a real blob per probe
    - Tests & tooling
      - Add a storage-metadata contract spec: every analyzer runs over every dummy fixture and must return ASCII scalars that fit S3's 2 KB metadata limit (`spec/analyzers/storage_metadata_constraints_spec.rb`)
      - Raise SimpleCov `minimum_coverage` to 90 when `CI=true` (50 for local single-file runs); upgrade simplecov to 1.2
      - Install Magika CLI in CI from the checksummed `cli/v1.1.0` tarball instead of piping the installer script
      - Remove the unused dummy `Document` model and its `documents` table
    - Docs & packaging
      - Ship `CHANGES.md` and `docs/upgrade_to_*.md` in the gem package
      - Requiring the gem before Rails (a script, or a `Bundler.require` order that loads it first) no longer raises `NameError: uninitialized constant Rails`: the engine and railtie require `rails/engine` / `rails/railtie` themselves
      - Document that `Matchers.mock_metadata` mocks `Analyzer.new` in the current thread only while a probe runs

- 4.1.1
  - **FIXED**
    - Fix size / metadata matchers raising on Minitest 6 after `Minitest::Mock` was extracted (https://github.com/igorkasyanchuk/active_storage_validations/issues/430). Matchers now stub via a singleton method and do not need `minitest-mock`
    - Fix Swedish `aspect_ratio` interpolation placeholders (`authorized_aspect_ratios`)
    - Fix `filename` error option for `UploadedFile` / `File` / `Pathname` attachables
    - Fix `with_audio` rejecting audio files: the audio analyzer now reports an `audio` metadata key, so `with_audio` works on audio attachments and not only on videos
    - Fix metadata analysis running again on every validation when the analyzer cannot extract the requested key (e.g. `duration` on an image). Unavailable metadata is now memoized on the blob, so those files are analyzed once. Files that yield no metadata at all (missing command-line tool, timed out command, unreadable file) are still retried
    - Fix `processable_file` accepting unprocessable files when `content_type` with `spoofing_protection` was declared on the same attribute. The cached `asv_content_type` counted as a successful analysis, so the media analyzer never ran. Content-type keys are no longer visible to the metadata validators
    - Fix `duration` rejecting media shorter than one second. The guard meant to catch unreadable metadata truncated the duration to an integer, so a 0.5s file reported `media_metadata_missing` instead of being compared against the bounds
    - Fix `content_type` and `aspect_ratio` keeping per-validation state on the validator instance. Active Model reuses one validator per class across threads, so concurrent validations could report another record's content type or aspect ratio — and, with `spoofing_protection`, compare a file against another file's detected type
    - Fix PDF first-page dimensions for sizes with two or more fractional digits (e.g. A4 `595.276 x 841.89`). The `pdfinfo` parser used to split extra digits into a second number, so height became `8`
    - Fix `ImageAnalyzer` support cache being keyed by instance. A new analyzer is built per attachable, so the cache never hit and retained every instance (and its attachable) for the process lifetime. It is now keyed by analyzer class
    - Fix `validate_limits_of` / `validate_processable_file_of` `#allow_blank` being a no-op (the matchers included the concern but never called it). `#allow_blank` now checks the validator option
    - Fix comparison matcher `#equal_to` matching looser bounds (e.g. `less_than_or_equal_to`). It now also requires `exact ±` the smallest unit to fail
    - Fix comparison matchers `#less_than_or_equal_to` / `#greater_than_or_equal_to` / `#between` matching exclusive bounds (e.g. `less_than`). They now require the inclusive endpoint itself to pass
    - Stop inserting an `active_storage_blobs` row from a bare `valid?` on a new record. `asv_*` metadata stays in memory on the unsaved blob and is written when the record is saved. Already-persisted blobs still `save!` so the cache survives `reload`
- **MISC**
  - Add a locale key / interpolation contract spec; include `ru` in `I18n.available_locales`
  - Clarify why `file_field` skips Proc `content_type` options when inferring the HTML `accept` attribute
  - Document the `analyze.active_storage_validations` notification alongside `timeout.active_storage_validations`
  - Remove an unreachable de-duplication guard in `ASVErrorable#add_error`; every offending file already gets its own error
  - Resolve the declared content type once per attachable instead of twice, saving a `find_signed!` query for attachables passed as a signed id
  - Collapse attachable type dispatch (Blob / UploadedFile / Hash / File / Pathname / signed id) into `ASVAttachableAdapter` used by validators, analyzers, and error filenames
  - Add Dependabot for GitHub Actions and the root Gemfile; upload SimpleCov from the Ruby 3.4 / Rails 8.1 / vips CI job (artifact only; Codecov upload removed)
  - Bump CI GitHub Actions to latest majors (`actions/checkout@v7`, `actions/upload-artifact@v7`)
  - Bump development gems (mini_magick, rubocop, rubocop-performance, simplecov, sqlite3, webmock, vernier) and the local Rails pin to 8.1.3.1
  - Remove invalid `validate_attached_of(...).allow_blank` matcher example (`attached` rejects `:allow_blank`)
  - Align bench workflow Actions with CI (`checkout` / `upload-artifact` v7); pin Magika CLI to `cli/v1.1.0`; run `apt-get update` once per job
  - Raise `CommandLineToolNotInstalledError` from a shared `ContentTypeAnalyzer` ancestor so both `file` and `magika` backends can be rescued together
  - Fail the suite when SimpleCov line coverage drops below 50% (`spec/spec_helper.rb`)
 
- 4.1.0
  - **ADDED**
    - Add `with_audio` validator and `validate_with_audio_of` matcher for requiring or forbidding an audio track in video files (https://github.com/igorkasyanchuk/active_storage_validations/issues/303). Use `with_audio: true` to require audio or `with_audio: { with: false }` to forbid it. Supports per-validator `timeout:` and matcher `#timeout`.

- 4.0.0
  - **BREAKING**
    - Drop support for Rails 6.1.4, 7.0.0 (we keep support for Rails >= 7.0.1)
    - Drop support for Ruby < 3.3 (`required_ruby_version` is now `>= 3.3.0`)
    - `FormBuilder#file_field` now automatically sets the HTML `accept` attribute from `content_type` validators (https://github.com/igorkasyanchuk/active_storage_validations/pull/415). Disable globally with `ActiveStorageValidations.infer_file_field_accept = false`, or per field with `infer_accept: false`
    - Analyzer commands (`ffprobe`, `pdfinfo`, `file`, ImageMagick `identify`, libvips) now default to a 10s `command_timeout` (https://github.com/igorkasyanchuk/active_storage_validations/issues/410). Most apps are unaffected; this is breaking for uploads whose metadata analysis legitimately takes longer than 10s (e.g. very large videos on slow/network storage). Raise globally, per validator with `timeout:`, or set `nil` to restore unbounded waits — see [upgrade guide](docs/upgrade_to_4.md)
  - **ADDED**
    - Add `#except_on` matcher option to support Rails `:except_on` validation option (available since Rails 8.0) (https://github.com/igorkasyanchuk/active_storage_validations/issues/380)
    - Add optional per-validator `timeout:` and `timeout.active_storage_validations` instrumentation for analyzer commands. Timed-out analysis fails closed using existing validation errors
    - Add `#timeout` matcher option for metadata validators (`dimension`, `aspect_ratio`, `duration`, `pages`, `processable_file`) and `content_type`
    - Add `spoofing_protection: :magika` backend (Google Magika CLI) for `content_type`; `true` still means `:file`. Cache stores `asv_content_type_backend`. Matcher: `#spoofing_protection` / `#spoofing_protection(:magika)` (https://github.com/igorkasyanchuk/active_storage_validations/issues/404)
  - **FIXED**
    - Fix `dimension: { min:, max: }` when both top-level bounds are set together (previously the second bound overwrote the first in `process_options`)
    - Fix Proc options with arity 0 (e.g. `-> { 2.kilobytes..7.kilobytes }`) being called with the record argument
    - Fix metadata matchers (`aspect_ratio`, `dimension`, …) crashing with `NoMethodError` when the same attribute also has `content_type` spoofing protection (matcher `Analyzer` stub now responds to `#content_type`)
  - **MISC**
    - Add support for Ruby 4.0 in CI matrix
    - Add [AGENTS.md](AGENTS.md) with codebase guide for AI coding agents
    - Add informational `benchmark/` suite for metadata validators (cold vs cached `asv_*`, vips vs mini_magick) with CI job and checked-in baseline
    - Migrate the gem test suite from Minitest to RSpec; add `rubocop-rspec` (https://github.com/igorkasyanchuk/active_storage_validations/issues/307). Consumer matcher APIs for RSpec and Minitest/shoulda are unchanged
    - Strengthen validator specs: comparison Proc options, `total_size` multi-file sums, `media_metadata_missing` / `attachment_missing`, duration/pages several-checks validity, Rails `:except_on`
    - Correct `spoofing_protection` docs: `file`/libmagic does not load the whole file into RAM; remote blobs are still streamed to a tempfile (https://github.com/igorkasyanchuk/active_storage_validations/issues/376)

  - To upgrade from version 3.x to 4.x, please read the [upgrade guide](docs/upgrade_to_4.md)

- 3.0.6
  - Fix `processable_file` rejecting formats with libvips untrusted loaders (e.g. SVG) after Rails enables `Vips.block_untrusted(true)` (https://github.com/igorkasyanchuk/active_storage_validations/issues/423). No impact on Rails versions that do not enable this Vips change (before 7.2.3.2 / 8.0.5.1 / 8.1.3.1, unless the app blocks untrusted loaders itself).
  - Fix validation of multiple new attachables with nil blob ids (https://github.com/igorkasyanchuk/active_storage_validations/pull/422) @tmnb

- 3.0.5
  - Fix issue when uploading a Blob and signed_id String that references the same Blob (https://github.com/igorkasyanchuk/active_storage_validations/issues/419)

- 3.0.4
  - Add `filename` error options for direct uploads (https://github.com/igorkasyanchuk/active_storage_validations/pull/414).

- 3.0.3
  - Fix issue with pdf having decimal dimensions (e.g. 200.3 pt) (https://github.com/igorkasyanchuk/active_storage_validations/issues/401) @tekin
  - Fix typos in I18n variables for `sv`, `uk`, `vi` and `zh-CN` locales, improve I18n issue detection (https://github.com/igorkasyanchuk/active_storage_validations/pull/403) @miry
  - Remove useless checks for parent relation, this bug was present from Rails `8.0.2` until `8.0.4` (excluded), because of Rails own bug (https://github.com/igorkasyanchuk/active_storage_validations/issues/377) @mth0158

- 3.0.2
  - Fix issue with active_storage_validations metadata not being saved if only running a `valid?` call  (https://github.com/igorkasyanchuk/active_storage_validations/issues/361)
  - Fix typo for English dimension translations (#https://github.com/igorkasyanchuk/active_storage_validations/issues/395)

- 3.0.1
  - Fix translation issues for German keys for pdf `pages` validator (`pages_not_greater_than_or_equal_to` / `pages_not_equal_to`)
  - Fix translation issues for Japanese keys (#https://github.com/igorkasyanchuk/active_storage_validations/issues/392)

- 3.0.0
  - Allow to perform dimension / aspect_ratio validations on single page pdf (https://github.com/igorkasyanchuk/active_storage_validations/pull/374)
  - Added `pages` validator to validate pdf number of pages (https://github.com/igorkasyanchuk/active_storage_validations/pull/374)
  - Added `equal_to` option to `duration`, `size`and `total_size` validators (https://github.com/igorkasyanchuk/active_storage_validations/pull/386)
  - To upgrade from version 2.x to 3.x, please read the [upgrade guide](docs/upgrade_to_3.md)

- 2.0.4
  - Fix issue when updating a child record through a parent (like: parent_model.update(child_attributes: { image: file })) for Rails >= 8.0.2 (https://github.com/igorkasyanchuk/active_storage_validations/pull/378)
  - Fix issue causing a stack error too deep edge case (not reproductible) because of the `after: :load_config_initializers` option (https://github.com/igorkasyanchuk/active_storage_validations/pull/382)

- 2.0.3
  - Allow to pass an Array, a splatted Array, or a single string for allowing / rejecting content_type matcher methods (https://github.com/igorkasyanchuk/active_storage_validations/pull/372)
  - Fix issue when an attachment was missing on a blob (https://github.com/igorkasyanchuk/active_storage_validations/pull/373)

- 2.0.2
  - Fix undesirable mutation of Marcel::TYPE_EXTS (https://github.com/igorkasyanchuk/active_storage_validations/issues/356)
  - Fix gem loading issue with Marcel custom initialisers (https://github.com/igorkasyanchuk/active_storage_validations/issues/355)

- 2.0.1
  - Fix for invalid content type validation ([PR #347](https://github.com/igorkasyanchuk/active_storage_validations/pull/347))
  - Fix issue with custom_metadata not working with external services such as S3 ([PR #349](https://github.com/igorkasyanchuk/active_storage_validations/pull/349))
  - Fix issue when using several matchers using different metadata keys ([PR #351](https://github.com/igorkasyanchuk/active_storage_validations/pull/351))

- 2.0.0
  - We are happy to release the `active_storage_validations` version 2! This major version add several features such as:
    - Add support for video & audio files
      - `dimension` validator now supports video files
      - `aspect_ratio` validator now supports video files
      - `processable_image` validator is now `processable_file` validator and supports image/video/audio
    - New validator added:
      -  `duration` validator has been added for audio / video files
    - Major performance improvement have been added: we now only perform the expensive io analysis operation on the newly attached files
    - All error messages have been given an upgrade and new variables that you can use
    - Complete rewrite of gem README
  - To upgrade from version 1.x to 2.x, please read the [upgrade guide](docs/upgrade_to_2.md)
  - Find the associated PRs here:
    - https://github.com/igorkasyanchuk/active_storage_validations/pull/310
    - https://github.com/igorkasyanchuk/active_storage_validations/pull/341

- 1.4.0
  - https://github.com/igorkasyanchuk/active_storage_validations/pull/324
  - https://github.com/igorkasyanchuk/active_storage_validations/pull/326
  - https://github.com/igorkasyanchuk/active_storage_validations/pull/332
  - https://github.com/igorkasyanchuk/active_storage_validations/pull/327
  - https://github.com/igorkasyanchuk/active_storage_validations/pull/325
  - https://github.com/igorkasyanchuk/active_storage_validations/pull/294

- 1.3.5
  - https://github.com/igorkasyanchuk/active_storage_validations/pull/322
  - https://github.com/igorkasyanchuk/active_storage_validations/pull/318
  - https://github.com/igorkasyanchuk/active_storage_validations/pull/313
  - https://github.com/igorkasyanchuk/active_storage_validations/pull/312
  - https://github.com/igorkasyanchuk/active_storage_validations/pull/306
  - https://github.com/igorkasyanchuk/active_storage_validations/pull/300
  - https://github.com/igorkasyanchuk/active_storage_validations/pull/299

- 1.3.4
  Bug fixes:
  - https://github.com/igorkasyanchuk/active_storage_validations/pull/296
  - https://github.com/igorkasyanchuk/active_storage_validations/pull/297

- 1.3.3
  Bug fixes:
  - https://github.com/igorkasyanchuk/active_storage_validations/pull/290/files
  - https://github.com/igorkasyanchuk/active_storage_validations/pull/289/files
  - https://github.com/igorkasyanchuk/active_storage_validations/pull/288/files

- 1.3.2
  Bug fixes:
  - https://github.com/igorkasyanchuk/active_storage_validations/pull/284
  - https://github.com/igorkasyanchuk/active_storage_validations/pull/285
  - https://github.com/igorkasyanchuk/active_storage_validations/pull/286

- 1.3.0
  - https://github.com/igorkasyanchuk/active_storage_validations/pull/256
  - https://github.com/igorkasyanchuk/active_storage_validations/pull/268
  - https://github.com/igorkasyanchuk/active_storage_validations/pull/267
  - https://github.com/igorkasyanchuk/active_storage_validations/pull/263

- 1.2.0
  Many improvements and fixes:
  - https://github.com/igorkasyanchuk/active_storage_validations/pull/236
  - https://github.com/igorkasyanchuk/active_storage_validations/pull/237
  - https://github.com/igorkasyanchuk/active_storage_validations/pull/238
  - https://github.com/igorkasyanchuk/active_storage_validations/pull/240
  - https://github.com/igorkasyanchuk/active_storage_validations/pull/245
  - https://github.com/igorkasyanchuk/active_storage_validations/pull/248
  - https://github.com/igorkasyanchuk/active_storage_validations/pull/251
  - https://github.com/igorkasyanchuk/active_storage_validations/pull/250
  - https://github.com/igorkasyanchuk/active_storage_validations/pull/247
  - https://github.com/igorkasyanchuk/active_storage_validations/pull/252
  - https://github.com/igorkasyanchuk/active_storage_validations/pull/253
  - https://github.com/igorkasyanchuk/active_storage_validations/pull/262


- 1.1.4
  Many improvements and fixes:
  - https://github.com/igorkasyanchuk/active_storage_validations/pull/235
  - https://github.com/igorkasyanchuk/active_storage_validations/pull/233
  - https://github.com/igorkasyanchuk/active_storage_validations/pull/232
  - https://github.com/igorkasyanchuk/active_storage_validations/pull/229
  - https://github.com/igorkasyanchuk/active_storage_validations/pull/228
  - https://github.com/igorkasyanchuk/active_storage_validations/pull/226
  - https://github.com/igorkasyanchuk/active_storage_validations/pull/161
  - https://github.com/igorkasyanchuk/active_storage_validations/pull/153
  - https://github.com/igorkasyanchuk/active_storage_validations/pull/221
  - https://github.com/igorkasyanchuk/active_storage_validations/pull/220


- 1.1.3
  - https://github.com/igorkasyanchuk/active_storage_validations/pull/217/files
  - drop Rails 6.0 from CI
  - added Rails 7.1 to CI

- 1.1.2
  - https://github.com/igorkasyanchuk/active_storage_validations/issues/213
  - https://github.com/igorkasyanchuk/active_storage_validations/pull/214
  - https://github.com/igorkasyanchuk/active_storage_validations/pull/206
  - https://github.com/igorkasyanchuk/active_storage_validations/pull/208

- 1.1.1
  - https://github.com/igorkasyanchuk/active_storage_validations/pull/202

- 1.0.4
  - Support for StringIO attachments https://github.com/igorkasyanchuk/active_storage_validations/pull/176
  - Support libvips < 8.8 https://github.com/igorkasyanchuk/active_storage_validations/pull/185
  - Test against Ruby 3.2

- 1.0.3
  - Fix missing block when using valid? method https://github.com/igorkasyanchuk/active_storage_validations/pull/174

- 1.0.2
  - Support using allowing and rejecting together on content type matcher https://github.com/igorkasyanchuk/active_storage_validations/pull/172

- 1.0.1
  - add ProcessableImageValidator https://github.com/igorkasyanchuk/active_storage_validations/pull/168
  - fix slowness https://github.com/igorkasyanchuk/active_storage_validations/pull/169

- 1.0.0
  - allow Procs as an input for validation options https://github.com/igorkasyanchuk/active_storage_validations/pull/135/files
  - new translation zh-CN https://github.com/igorkasyanchuk/active_storage_validations/pull/162
  - drop support of Rails 5.2 (in tests, but in reality it should work, just check PR in this version)

- 0.9.8
  - Fix a file extension issue in Metadata#read_image https://github.com/igorkasyanchuk/active_storage_validations/pull/148/files
  - Dynamic exception class https://github.com/igorkasyanchuk/active_storage_validations/pull/150
  - Display All Validation Errors https://github.com/igorkasyanchuk/active_storage_validations/pull/152

- 0.9.7
  - tests for Rails 7 and Ruby 3.1 https://github.com/igorkasyanchuk/active_storage_validations/pull/143
  - Fix pt-BR translations https://github.com/igorkasyanchuk/active_storage_validations/pull/132
  - Remove references to image/jpg content type https://github.com/igorkasyanchuk/active_storage_validations/pull/144
  - missing relationship in dummy app https://github.com/igorkasyanchuk/active_storage_validations/pull/142
  - References Marcel::TYPES only for Rails < 6.1 https://github.com/igorkasyanchuk/active_storage_validations/pull/138
  - better clarify how to define between size https://github.com/igorkasyanchuk/active_storage_validations/pull/133
  - Add vips support for aspect ratio and dimension validators https://github.com/igorkasyanchuk/active_storage_validations/pull/140

- 0.9.6
  - Add min_size and max_size to :file_size_out_of_range error message https://github.com/igorkasyanchuk/active_storage_validations/pull/134
  - Reference Marcel::EXTENSIONS https://github.com/igorkasyanchuk/active_storage_validations/pull/137

- 0.9.5
  - add latest Rails support in tests https://github.com/igorkasyanchuk/active_storage_validations/pull/126
  - file permissions set to 0644 https://github.com/igorkasyanchuk/active_storage_validations/pull/125
  - use Marcel to detect the correct content_type https://github.com/igorkasyanchuk/active_storage_validations/pull/123
  - enable CI for pull requests https://github.com/igorkasyanchuk/active_storage_validations/pull/124

- 0.9.4
  - Add with_message for dimension_validator_matcher  https://github.com/igorkasyanchuk/active_storage_validations/pull/117
  - Fix typo in tests https://github.com/igorkasyanchuk/active_storage_validations/pull/119
  - Raise error when undefined mime type symbol is given https://github.com/igorkasyanchuk/active_storage_validations/pull/120
  - Enable to set message on error of attached validator https://github.com/igorkasyanchuk/active_storage_validations/pull/121


- 0.9.3
  - Added Vietnamese translation https://github.com/igorkasyanchuk/active_storage_validations/pull/108
  - Allow regex in content_type arrays https://github.com/igorkasyanchuk/active_storage_validations/pull/104
  - fixes for spanish translation https://github.com/igorkasyanchuk/active_storage_validations/pull/114, https://github.com/igorkasyanchuk/active_storage_validations/pull/115/

- 0.9.2
  - moved to github actions (@StefSchenkelaars)
  - better support for ruby 3, rails 6.1 (@StefSchenkelaars)

- 0.9.1
  - ensure to detach attachment before validating attached https://github.com/igorkasyanchuk/active_storage_validations/pull/81
  - fixing UK translations https://github.com/igorkasyanchuk/active_storage_validations/pull/92
  - added ES translation https://github.com/igorkasyanchuk/active_storage_validations/pull/90
  - Rails 6.1 support https://github.com/igorkasyanchuk/active_storage_validations/pull/94
  - added dutch translation https://github.com/igorkasyanchuk/active_storage_validations/pull/97
  - fix deprecation warnings for Ruby 2.7 https://github.com/igorkasyanchuk/active_storage_validations/pull/100

- 0.9.0
  - added Turkish translation https://github.com/igorkasyanchuk/active_storage_validations/pull/75
  - fixed attached matcher https://github.com/igorkasyanchuk/active_storage_validations/pull/79

- 0.8.9
  - better DE translations

- 0.8.8
  - Fix something wrong with params: https://github.com/igorkasyanchuk/active_storage_validations/pull/66 @High5Apps
  - added Janapese language (@willnet)

- 0.8.7
  - added test matchers https://github.com/igorkasyanchuk/active_storage_validations/pull/56

- 0.8.6
  - added FR, RU, UK translations

- 0.8.5
  - small tweaks

- 0.8.4
  - fixed error messages for aspect ratio validation PR #44
  - better limit validation for rails 6 PR #45

- 0.8.3
  - added pt-BR translation PR #40

- 0.8.2
  - allows to pass Regexp for a content type validation: `validates :avatar, content_type: /\Aimage\/.*\z/`

- 0.8.1
  - allows to pass symbol for a content type validation: `validates :avatar, attached: true, content_type: :png`

- 0.8.0
  - added aspect ratio validator
  - support for Rails 5.2 and Rails 6

- 0.7.1
  - added dimension validator

