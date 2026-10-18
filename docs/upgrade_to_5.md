# Upgrading to 5.x

**TL;DR: most applications bump the gem and keep the same code.**

- Same Ruby (`>= 3.3`) and Rails (`>= 7.0.1`) as 4.x
- No validator, option, matcher method, or I18n key was renamed or removed
- The breaking changes are edge cases: custom messages interpolating undocumented options, options that already crashed at runtime, empty authorized lists, and analysis failures that now fail closed
- The changelog is long because of the **FIXED** list: hardening found in review, none of it requiring a code change. The few fixes that can change whether a real upload passes are listed in [Fixes that can change validation results](#fixes-that-can-change-validation-results)

## Do I need to change anything?

Go through this table. If no row matches, you are done.

| If your app… | Then… | Details |
| --- | --- | --- |
| Has a custom `message:` (or a gem I18n key overridden in your locales) interpolating a raw option such as `%{less_than}` | Use the documented value (`%{max}`, `%{min}`, `%{exact}`, …) | [Options no longer forwarded](#validator-options-are-no-longer-forwarded-to-errorsadd) |
| Reads raw options (`less_than_or_equal_to`, `width`, …) from `errors.details` | Read the documented value, or the option from the model | [Options no longer forwarded](#validator-options-are-no-longer-forwarded-to-errorsadd) |
| Passes an endless / beginless Range (`between: 1.kilobyte..`, `width: { in: 100.. }`) | Use a single-bound option | [Unbounded ranges](#unbounded-between--dimension-ranges) |
| Passes an empty `content_type` / `aspect_ratio` list (`[]`, or a Proc that can return `[]`) | Remove the validator, or expect every file to be rejected | [Empty lists](#empty-content_type--aspect_ratio-lists-fail-closed) |
| Uses an `aspect_ratio` value that is not an exact `is_x_y` (`:is_16_9square`) | Fix the typo | [Strict `aspect_ratio`](#aspect_ratio-options-are-validated-strictly) |
| Uses `with_audio: { with: false }` where `ffprobe` may be missing | Install `ffmpeg` wherever validations run | [`with_audio` fails closed](#with_audio--with-false--fails-closed) |
| Matches on `:content_type_spoofed`, or overrides that locale key | Also handle `:content_type_analysis_failed` | [`content_type_analysis_failed`](#content_type_analysis_failed-error) |
| Has specs asserting the English wording of `duration` errors in a non-English locale | Update the expected strings | [Localized duration values](#localized-duration-values) |

Optional, ops only: three analyzer fixes change cached metadata, so blobs analyzed under 4.x can be re-analyzed. See [Already-analyzed blobs](#already-analyzed-blobs-optional).

## Breaking changes (edge cases)

### Validator options are no longer forwarded to `errors.add`

**Who is affected?** Only custom messages interpolating a raw option, and code reading those options from `errors.details`. The documented values (`%{min}`, `%{max}`, `%{exact}`, `%{file_size}`, `%{width}`, `%{height}`, `%{length}`, `%{count}`, `%{authorized_human_content_types}`, `%{filename}`, … — see each validator's "Error messages (I18n)" README section) are unchanged, as are `validator_type` and `filename` in `errors.details`.

**What changed.** Up to 4.x, every option given to a validator (except `with:` / `in:`) was passed along to `errors.add`. `errors.details` therefore carried Procs and Ranges (and could not be serialized as JSON), configuration such as `timeout:` and `spoofing_protection:` leaked into the I18n interpolation arguments, and custom messages could interpolate raw options that were never documented.

Version 5 aligns with Rails' built-in validators (`LengthValidator::RESERVED_OPTIONS`, `NumericalityValidator#filtered_options`): the check options (`less_than:`, `greater_than_or_equal_to:`, `between:`, `equal_to:`, `width:`, `height:`, `min:`, `max:`, `with:`, `in:`, …) and the gem configuration (`timeout:`, `spoofing_protection:`) never reach `errors.add`. Rails' own options (`message:`, `if:`, `on:`, `strict:`, …) are handled by Rails as before.

**How to fix: custom messages.** Messages (inline `message:` or overridden gem I18n keys) interpolating a raw option used to work by accident. They now raise `I18n::MissingInterpolationArgument` when rendered (`errors.full_messages`, `errors.messages`, form error helpers):

```ruby
# 4.x: rendered "must be at most 2048 bytes"
# 5.x: raises I18n::MissingInterpolationArgument (:less_than_or_equal_to)
validates :avatar, size: { less_than_or_equal_to: 2.kilobytes, message: "must be at most %{less_than_or_equal_to} bytes" }

# 5.x: use the documented value
validates :avatar, size: { less_than_or_equal_to: 2.kilobytes, message: "must be at most %{max}" }
```

| Validators | Raw option (no longer available) | Use instead |
| --- | --- | --- |
| `size`, `total_size`, `duration`, `pages` | `%{less_than}`, `%{less_than_or_equal_to}` | `%{max}` |
| | `%{greater_than}`, `%{greater_than_or_equal_to}` | `%{min}` |
| | `%{between}` | `%{min}` and `%{max}` |
| | `%{equal_to}` | `%{exact}` |
| `dimension` | `%{width}` / `%{height}` / `%{min}` / `%{max}` as declared (Hash or Range) | the resolved values each message documents: `%{min}` / `%{max}` for `*_not_included_in`, `%{length}` for `*_not_equal_to` and `*_than_or_equal_to`, `%{width}` / `%{height}` for `dimension_min_not_included_in` / `dimension_max_not_included_in` |
| `content_type`, `aspect_ratio` | `%{with}` / `%{in}` | already not forwarded in 4.x — nothing to change |
| all validators | `%{timeout}`, `%{spoofing_protection}` | configuration, never meant for messages |

Find candidates with:

```sh
git grep -nE '%\{(less_than|greater_than|between|equal_to|timeout|spoofing_protection)' app config
```

**How to fix: `errors.details`.**

```ruby
record.errors.details[:avatar].first

# 4.x
# => { error: :file_size_not_less_than_or_equal_to, less_than_or_equal_to: 2048, validator_type: :size,
#      min: nil, exact: nil, max: "2 KB", file_size: "5 KB", filename: "file_5ko" }

# 5.x
# => { error: :file_size_not_less_than_or_equal_to, validator_type: :size,
#      min: nil, exact: nil, max: "2 KB", file_size: "5 KB", filename: "file_5ko" }
```

Read the documented value instead (`max` here), or the option itself from the model: `User.validators_on(:avatar).grep(ActiveStorageValidations::SizeValidator).first.options[:less_than_or_equal_to]`.

### Unbounded `between:` / dimension ranges

**Who is affected?** Only apps that already crashed on the first invalid file (or on the first `valid?` for unbounded dimension ranges). A bounded `between: 1.kilobyte..5.megabytes` is unchanged.

**What changed.** `size`, `total_size`, `duration` and `pages` used to accept endless / beginless ranges (`between: 1.kilobyte..`). The comparison itself worked, but building the error message for the first invalid file raised `RangeError`. The same applied to `dimension` `width` / `height` `{ in: }` and to `{ min: min_width..min_height }` / `{ max: }`, which raised `RangeError` from `Range#min` / `#max` on the first `valid?`. Such options now fail fast at boot:

```
ArgumentError: You must pass a Range with both bounds to :between (use :greater_than_or_equal_to or :less_than_or_equal_to for a single bound)
```

**How to fix.** Use a single-bound option:

```ruby
# 4.x: loaded, RangeError on the first invalid file
validates :avatar, size: { between: 1.kilobyte.. }
validates :video, duration: { between: ..5.minutes }
validates :photo, dimension: { width: { in: 100.. } }

# 5.x
validates :avatar, size: { greater_than_or_equal_to: 1.kilobyte }
validates :video, duration: { less_than_or_equal_to: 5.minutes }
validates :photo, dimension: { width: { min: 100 } }
```

Ranges returned by Procs are not checked at boot (Procs bypass `check_validity!`). They no longer raise either, but prefer a single-bound option there too so the error message gets a real bound.

### Empty `content_type` / `aspect_ratio` lists fail closed

**Who is affected?** Only `with: []` / `in: []`, or a Proc that can return an empty list.

**What changed.** A static empty list (`content_type: { with: [] }`, `aspect_ratio: { in: [] }`) now raises `ArgumentError` at boot. A Proc that returns `[]` (or `nil`) used to skip the validator and accept every file; it now rejects the attachment (`content_type_invalid` / `aspect_ratio_invalid`).

**How to fix.** Treat an empty Proc result as "nothing is authorized", like Rails `inclusion: { in: [] }`. If you meant "accept anything" in some cases, make the validator conditional (`if:` / `unless:`) instead of returning `[]`.

### `aspect_ratio` options are validated strictly

**Who is affected?** Only a typo or extra suffix on an `is_x_y` option.

**What changed.** `ASPECT_RATIO_REGEX` was not anchored, so options such as `:is_16_9_extra` or `:is_16_9square` passed `check_validity!` and were silently validated as `16:9`. Only the named ratios (`:square`, `:portrait`, `:landscape`) and exact `is_<width>_<height>` values (`:is_16_9`, `"is_4_3"`) are accepted now; anything else raises `ArgumentError` at boot with the accepted formats.

**How to fix.**

```ruby
# 4.x: loaded and behaved like :is_16_9
validates :avatar, aspect_ratio: :is_16_9square

# 5.x
validates :avatar, aspect_ratio: :is_16_9
```

### `with_audio: { with: false }` fails closed

**Who is affected?** Environments where `ffprobe` is missing (CI, development machines, slim production images) with a model using `with_audio: { with: false }`. This is the only breaking case that can turn a passing upload into a rejection without a misconfigured option.

**What changed.** Empty analyzer metadata means the file could not be analyzed at all: `ffprobe` is not installed or [timed out](../README.md#configuration), the file is unreadable, or its media type is unsupported. In 4.x that empty result was read as "no audio track", so `with_audio: { with: false }` accepted every such file (and `with: true` reported `audio_missing`). Both now add `media_metadata_missing`, like `dimension`, `duration`, `aspect_ratio`, `pages` and `processable_file` do. Images and PDFs are still treated as having no audio track.

**How to fix.** Install `ffmpeg` (which ships `ffprobe`) wherever validations run, raise the per-validator `timeout:` if large videos time out, and update specs that expected `audio_missing` for unanalyzable files. The `validate_with_audio_of` matcher is unchanged.

### `content_type_analysis_failed` error

**Who is affected?** Only code that matches the error type, and locale files that override `content_type_spoofed`. The file is still rejected.

**What changed.** With `spoofing_protection`, a spoofing analysis that produced nothing (`file` / `magika` command timed out, unsupported file, invalid CLI output) used to be reported as `content_type_spoofed`, as if the file had been analyzed and found spoofed. It now adds a dedicated `content_type_analysis_failed` error, shipped in every bundled locale and exposing the same values as `content_type_invalid`.

**How to fix.**

- Code matching on the error type (`errors.of_kind?(:avatar, :content_type_spoofed)`, `errors.where(:avatar, :content_type_spoofed)`, `errors.details`): also handle `:content_type_analysis_failed`
- Locale files overriding `content_type_spoofed`: override the new key as well

```yml
en:
  errors:
    messages:
      content_type_analysis_failed:
        one: "could not be verified (authorized content type is %{authorized_human_content_types})"
        other: "could not be verified (authorized content types are %{authorized_human_content_types})"
```

## Fixes that can change validation results

These are bug fixes, not breaking changes, and none needs a code change. They are listed here because a file that passed under 4.x can now fail (or the reverse) if you hit that case. Everything else in the changelog's **FIXED** list only removes crashes or matcher false positives.

| Validator | 4.x | 5.x |
| --- | --- | --- |
| `size`, `total_size`, `duration`, `pages` with a bound of `0` (`equal_to: 0`, `greater_than_or_equal_to: 0`) | Check skipped, every file rejected | Bound applied |
| `limit: { max: 0 }` / `{ min: 0 }` | Check skipped, records with no files rejected | Bound applied: no files passes `max: 0`, any file fails it |
| `dimension` `width` / `height` `{ max: 0 }` (or a Proc returning `0`) | Check skipped, every file accepted | Bound applied |
| `dimension` exclusive `in:` (`400...600`) | 600 accepted | 600 rejected |
| `size`, `limit`, `total_size` with attachments marked for destruction | Doomed files counted | Ignored, like `attached:` |
| `aspect_ratio` `is_x_y` | Exact to 3 decimals: 1366×768, 854×480 rejected as `:is_16_9` | 1-pixel tolerance on either axis |
| `duration` | Rounded to 0.1s before comparing: 1.96s failed `less_than: 2.seconds` | Exact value compared ♻️ |
| `duration` on WebM / Matroska audio (browser `MediaRecorder` Opus) | `media_metadata_missing` | Container duration used ♻️ |
| `processable_file` on an empty media container (zero streams) | Accepted (also by `with_audio: { with: false }`) | Rejected ♻️ |
| `content_type` `spoofing_protection` on Marcel 2 / Rails main (8.2+) | `audio/aac`, `application/xml`, `audio/mp4` rejected | Accepted |
| `content_type` `spoofing_protection` with a blank declared content type | Mismatch check skipped | Checked against the filename-resolved type |
| `with_audio: { with: -> { … } }` | Proc treated as truthy, every file failed | Proc evaluated |

♻️ = the old result is cached on blobs analyzed under 4.x, see below.

### Already-analyzed blobs (optional)

Three analyzer fixes change what is cached in `asv_*` blob metadata. They do not require a code change, but blobs already validated under 4.x keep the old metadata until you clear it:

- `asv_duration` was rounded to 0.1s
- `asv_duration` was empty for WebM / Matroska audio
- Empty media containers were cached as `{ audio: false, video: false }`, which `processable_file` read as a successful analysis

Call `blob.remove_active_storage_validations_metadata!` to re-analyze those blobs. On a persisted blob the method now `save!`s the cleared cache (it used to only mutate memory, so `reload` restored the old `asv_*` keys). Non-`asv_*` custom metadata is kept.

## Other changes that can show up without a code change

### Localized duration values

`duration` error messages humanize `%{duration}`, `%{min}`, `%{max}` and `%{exact}` in the current locale (`1 minute et 30 secondes` in French) through the new `active_storage_validations.duration` keys shipped in every bundled locale, instead of the English-only `ActiveSupport::Duration#inspect`. The message text changes for non-English locales, so specs asserting the exact wording need an update. Locales the gem does not ship fall back to the English wording; to localize one of them, add the seven unit keys and the sentence connectors (see `config/locales/en.yml` in the gem):

```yml
pt:
  active_storage_validations:
    duration:
      minutes:
        one: "%{count} minuto"
        other: "%{count} minutos"
      seconds:
        one: "%{count} segundo"
        other: "%{count} segundos"
      # years, months, weeks, days, hours follow the same one / other pattern
      connectors:
        words_connector: ", "
        two_words_connector: " e "
        last_word_connector: " e "
```

### `content_type` Proc results are checked

A `content_type` Proc returning an unsupported type (e.g. `"image/jpg"`) used to reject every file with a blank message. It now raises, when the Proc is evaluated, the same `ArgumentError` static options get at boot. Fix the Proc (`"image/jpeg"`, or a Marcel shorthand such as `:jpeg`).

### Image analyzer default when Rails has not set a processor

When `ActiveStorage.variant_processor` is unset, image analyzers now fall back to `:vips` instead of `:mini_magick` (matching the README recommendation and Rails 7.1+). A fully booted Rails app still uses whatever Rails set (`:mini_magick` on 7.0, `:vips` on 7.1+). Set `config.active_storage.variant_processor = :mini_magick` to keep ImageMagick.

### Internal API removals

Only relevant if you monkey-patch the gem:

- `ASVAttachableAdapter` handlers expose only `content_type`, `filename` and `with_media_path(tempfile, max_bytes: nil)`; `read` / `rewind` are gone
- `ASVAttachable#attachable_io`, `#rewind_attachable_io`, `#attachable_content_type_rails_like` and `#supports_pathname_attachment?` are removed
- `ASVOptionable#flatten_options` returns only the validator check options
- Matchers build their probe attachments on `StringIO`s; `Matchers::ASVAttachable#dummy_blob` is removed

See [CHANGES.md](../CHANGES.md) for the full list of fixes, grouped by validator, analyzer and matcher.
