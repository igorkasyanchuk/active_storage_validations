# Upgrading to 5.x

Version 5 looks like a large release because the changelog is long. In practice it is a **light upgrade**:

- Same Ruby (`>= 3.3`) and Rails (`>= 7.0.1`) as 4.x
- No validator, option, matcher method, or I18n key was renamed or removed
- The **breaking changes are edge cases**: custom messages interpolating undocumented options, options that already crashed at runtime, empty authorized lists, and fail-closed analysis
- The long **FIXED** list is hardening found in review. None of those bugs were reported as GitHub issues. A few can affect real uploads if you hit that case; none require an application code change

**Most applications bump the gem and keep the same code.** Use the checklist below; if nothing matches, you are done. Details further down are only for the cases that do.

## Do I need to change anything?

Skip the rest of this guide unless any of these apply:

1. Custom `message:` strings — or gem I18n keys overridden in your locale files — interpolating a raw option (`%{less_than}`, `%{less_than_or_equal_to}`, …) instead of the documented value (`%{max}`, …)
2. Code reading those raw options from `errors.details`
3. `between:` / `dimension` `{ in: }` / `{ min: }` / `{ max: }` with an endless or beginless Range (`1.kilobyte..`)
4. `content_type` / `aspect_ratio` with an empty list (`[]`, or a Proc that returns `[]`)
5. `aspect_ratio` values that are not exact (`:is_16_9square`)
6. `with_audio: { with: false }` where `ffprobe` is missing
7. Code matching on `:content_type_spoofed` specifically, or a locale override of that key (analysis failures now use `content_type_analysis_failed`)
8. Specs asserting the exact English wording of duration error values in a non-English locale

If none match, bump and go. Two duration analyzer fixes also change cached `asv_duration` on already-analyzed blobs (WebM / Matroska audio, and files within 0.1s of a bound); that is optional ops, not a code change — see [Already-analyzed blobs](#already-analyzed-blobs-optional).

## Breaking changes (edge cases)

### Validator options are no longer forwarded to `errors.add`

Up to 4.x, every option given to a validator (except `with:` / `in:`) was passed along to `errors.add`. `errors.details` therefore carried Procs and Ranges (and could not be serialized as JSON), configuration such as `timeout:` and `spoofing_protection:` leaked into the I18n interpolation arguments, and custom messages could interpolate raw options that were never documented.

Version 5 aligns with Rails' built-in validators (`LengthValidator::RESERVED_OPTIONS`, `NumericalityValidator#filtered_options`): the check options (`less_than:`, `greater_than_or_equal_to:`, `between:`, `equal_to:`, `width:`, `height:`, `min:`, `max:`, `with:`, `in:`, …) and the gem configuration (`timeout:`, `spoofing_protection:`) never reach `errors.add`. Rails' own options (`message:`, `if:`, `on:`, `strict:`, …) are handled by Rails as before.

The values each validator documents under its "Error messages (I18n)" README section (`%{min}`, `%{max}`, `%{exact}`, `%{file_size}`, `%{width}`, `%{height}`, `%{length}`, `%{count}`, `%{authorized_human_content_types}`, `%{filename}`, …) are unchanged, as are `validator_type` and `filename` in `errors.details`.

**Who is affected?** Almost nobody. Only custom messages interpolating a raw option, and code that read those options from `errors.details`.

1. Custom `message:` strings — and gem I18n keys overridden in your locale files — interpolating a raw option. They used to work by accident and now raise `I18n::MissingInterpolationArgument` when the message is rendered (`errors.full_messages`, `errors.messages`, form error helpers):

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

2. Code reading raw options from `errors.details`:

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

`size`, `total_size`, `duration` and `pages` used to accept endless / beginless ranges (`between: 1.kilobyte..`). The comparison itself worked, but building the error message for the first invalid file raised `RangeError`. Such options now fail fast at boot:

```
ArgumentError: You must pass a Range with both bounds to :between (use :greater_than_or_equal_to or :less_than_or_equal_to for a single bound)
```

```ruby
# 4.x: loaded, RangeError on the first invalid file
validates :avatar, size: { between: 1.kilobyte.. }
validates :video, duration: { between: ..5.minutes }

# 5.x
validates :avatar, size: { greater_than_or_equal_to: 1.kilobyte }
validates :video, duration: { less_than_or_equal_to: 5.minutes }
```

Ranges returned by Procs are not checked at boot (Procs bypass `check_validity!`). They no longer raise either, but prefer a single-bound option there too so the error message gets a real bound.

The same boot check applies to `dimension` `width` / `height` `{ in: }` and to `{ min: min_width..min_height }` / `{ max: }`. Those used to load and raise `RangeError` from `Range#min` / `#max` on the first `valid?`. Use `{ width: { min: 100 } }` or `{ width: { max: 800 } }` for a single bound.

**Who is affected?** Only apps that already crashed on the first invalid file (or the first `valid?` for unbounded dimension ranges). A bounded `between: 1.kilobyte..5.megabytes` is unchanged.

### Empty `content_type` / `aspect_ratio` lists fail closed

A static empty list (`content_type: { with: [] }`, `aspect_ratio: { in: [] }`) now raises `ArgumentError` at boot. A Proc that returns `[]` (or `nil`) used to skip the validator and accept every file; it now rejects the attachment (`content_type_invalid` / `aspect_ratio_invalid`). Treat an empty Proc result as "nothing is authorized", like Rails `inclusion: { in: [] }`.

**Who is affected?** Only `with: []` / `in: []`, or a Proc that can return an empty list.

### `aspect_ratio` options are validated strictly

`ASPECT_RATIO_REGEX` was not anchored, so options such as `:is_16_9_extra` or `:is_16_9square` passed `check_validity!` and were silently validated as `16:9`. Only the named ratios (`:square`, `:portrait`, `:landscape`) and exact `is_<width>_<height>` values (`:is_16_9`, `"is_4_3"`) are accepted now; anything else raises `ArgumentError` at boot with the accepted formats. Fix the value:

```ruby
# 4.x: loaded and behaved like :is_16_9
validates :avatar, aspect_ratio: :is_16_9square

# 5.x
validates :avatar, aspect_ratio: :is_16_9
```

**Who is affected?** Only a typo / extra suffix on an `is_x_y` option.

### `with_audio: { with: false }` fails closed

Empty analyzer metadata means the file could not be analyzed at all: `ffprobe` is not installed or [timed out](../README.md#configuration), the file is unreadable, or its media type is unsupported. In 4.x that empty result was read as "no audio track", so `with_audio: { with: false }` accepted every such file (and `with: true` reported `audio_missing`). Both now add `media_metadata_missing`, like `dimension`, `duration`, `aspect_ratio`, `pages` and `processable_file` do. Images and PDFs are still treated as having no audio track.

**Who is affected?** Environments where `ffprobe` is missing (CI, development machines, slim production images) with a model using `with_audio: { with: false }` — the only breaking case that can change a passing upload to a rejection without a misconfigured option. Install `ffmpeg` (which ships `ffprobe`) wherever validations run, raise the per-validator `timeout:` if large videos time out, and update specs that expected `audio_missing` for unanalyzable files. The `validate_with_audio_of` matcher is unchanged.

### `content_type_analysis_failed` error

With `spoofing_protection`, a spoofing analysis that produced nothing (`file` / `magika` command timed out, unsupported file, invalid CLI output) used to be reported as `content_type_spoofed`, as if the file had been analyzed and found spoofed. It now adds a dedicated `content_type_analysis_failed` error, shipped in every bundled locale and exposing the same values as `content_type_invalid`. The validation still fails closed.

**Who is affected?** Only code that matches the error type, and locale files that override `content_type_spoofed`. The file is still rejected.

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

### Already-analyzed blobs (optional)

Two duration analyzer fixes change what is stored as `asv_duration`. They do not require a code change. If you already validated those files under 4.x, the old metadata stays until you clear it:

- WebM / Matroska audio (e.g. browser `MediaRecorder` Opus recordings) used to get an empty `asv_duration`
- Duration was rounded to 0.1s before comparing, so a 1.96s file could fail `less_than: 2.seconds`

Call `blob.remove_active_storage_validations_metadata!` to re-analyze those blobs.

### `content_type` Proc results are checked

A `content_type` Proc returning an unsupported type (e.g. `"image/jpg"`) used to reject every file with a blank message. It now raises, when the Proc is evaluated, the same `ArgumentError` static options get at boot. Fix the Proc (`"image/jpeg"`, or a Marcel shorthand such as `:jpeg`).

### Internal API removals

Only relevant if you monkey-patch the gem:

- `ASVAttachableAdapter` handlers expose only `content_type`, `filename` and `with_media_path(tempfile, max_bytes: nil)`; `read` / `rewind` are gone
- `ASVAttachable#attachable_io`, `#rewind_attachable_io`, `#attachable_content_type_rails_like` and `#supports_pathname_attachment?` are removed
- `ASVOptionable#flatten_options` returns only the validator check options
- Matchers build their probe attachments on `StringIO`s; `Matchers::ASVAttachable#dummy_blob` is removed

### Image analyzer default when Rails has not set a processor

When `ActiveStorage.variant_processor` is unset, image analyzers now fall back to `:vips` instead of `:mini_magick` (matching the README recommendation and Rails 7.1+). A fully booted Rails app still uses whatever Rails set (`:mini_magick` on 7.0, `:vips` on 7.1+). Set `config.active_storage.variant_processor = :mini_magick` to keep ImageMagick.

See [CHANGES.md](../CHANGES.md) for the full list of review-found fixes (Marcel 2 aliases, exclusive `dimension` ranges, Windows analyzer spawn, ImageMagick GIF frames, Hash attachables without a filesystem path, matcher bounds, …). None of them require a migration.
