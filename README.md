[<img src="https://github.com/igorkasyanchuk/rails_time_travel/blob/main/docs/more_gems.png?raw=true"
/>](https://www.railsjazz.com/?utm_source=github&utm_medium=top&utm_campaign=active_storage_validations)

# Active Storage Validations

[![CI](https://github.com/igorkasyanchuk/active_storage_validations/actions/workflows/main.yml/badge.svg)](https://github.com/igorkasyanchuk/active_storage_validations/actions/workflows/main.yml)
[![RailsJazz](https://github.com/igorkasyanchuk/rails_time_travel/blob/main/docs/my_other.svg?raw=true)](https://www.railsjazz.com)
[![https://www.patreon.com/igorkasyanchuk](https://github.com/igorkasyanchuk/rails_time_travel/blob/main/docs/patron.svg?raw=true)](https://www.patreon.com/igorkasyanchuk)

[!["Buy Me A Coffee"](https://github.com/igorkasyanchuk/get-smart/blob/main/docs/snapshot-bmc-button-small.png?raw=true)](https://buymeacoffee.com/igorkasyanchuk)

Active Storage Validations is a gem that allows you to add validations for Active Storage attributes.

This gems is doing it right for you! Just use `validates :avatar, attached: true, content_type: 'image/png'` and that's it!

## Table of Contents

- [Getting started](#getting-started)
  - [Installation](#installation)
  - [Error messages (I18n)](#error-messages-i18n)
  - [Using image metadata validators](#using-image-metadata-validators)
  - [Using video and audio metadata validators](#using-video-and-audio-metadata-validators)
  - [Using pdf metadata validators](#using-pdf-metadata-validators)
  - [Using content type spoofing protection validator option](#using-content-type-spoofing-protection-validator-option)
  - [Configuration](#configuration)
- [Validators](#validators)
  - [Attached](#attached)
  - [Limit](#limit)
  - [Content type](#content-type)
  - [Size](#size)
  - [Total size](#total-size)
  - [Dimension](#dimension)
  - [Duration](#duration)
  - [Aspect ratio](#aspect-ratio)
  - [Processable file](#processable-file)
  - [Pages](#pages)
- [Upgrading](#upgrading)
- [Internationalization (I18n)](#internationalization-i18n)
- [Test matchers](#test-matchers)
- [Contributing](#contributing)
- [Additional information](#additional-information)

## Getting started

### Installation

Active Storage Validations work with Rails 7.0.1 onwards. Add this line to your application's Gemfile:

```ruby
gem 'active_storage_validations'
```

And then execute:

```sh
$ bundle
```

### Error messages (I18n)

Once you have installed the gem, I18n error messages will be added automatically to your app. See [Internationalization (I18n)](#internationalization-i18n) section for more details.

### Using image metadata validators

Optionally, to use the image metadata validators (`dimension`, `aspect_ratio` and `processable_file`), you will have to add one of the corresponding gems:

```ruby
gem 'ruby-vips', '>= 2.1.0'
# Or
gem 'mini_magick', '>= 4.9.5'
```

Plus, you have to be sure to have the corresponding command-line tool installed on your system (`libvips` for `ruby-vips`, or ImageMagick for `mini_magick` — both locally and in CI / production).

We recommend **libvips** (`ruby-vips` + `config.active_storage.variant_processor = :vips`) for these validators. Rails already defaults Active Storage variants to libvips ([`ActiveStorage::Variant`](https://api.rubyonrails.org/classes/ActiveStorage/Variant.html)), and our [image processor benchmarks](benchmark/BASELINE.md#image-processors--vips-vs-mini_magick) show cold metadata analysis is about **8× faster** than MiniMagick/ImageMagick on the same machine and fixtures. Warm validations (cached `asv_*` metadata) are similar for both.

### Using video and audio metadata validators

To use the video and audio metadata validators (`dimension`, `aspect_ratio`, `processable_file` and `duration`), you will not need to add any gems. However you will need to have the `ffmpeg` command-line tool installed on your system (once again, be sure to have it installed both on your local and in your CI / production environments).

### Using pdf metadata validators

To use the pdf metadata validators (`dimension`, `aspect_ratio`, `processable_file` and `pages`), you will not need to add any gems. However you will need to have the `poppler` tool installed on your system (once again, be sure to have it installed both on your local and in your CI / production environments).

### Using content type spoofing protection validator option

To use the `spoofing_protection` option with the `content_type` validator:

- Default backend (`true` / `:file`): the UNIX [`file`](https://en.wikipedia.org/wiki/File_(command)) command (usually preinstalled on UNIX systems)
- Magika backend (`:magika`): the [Google Magika](https://github.com/google/magika) CLI — install via their [install script](https://securityresearch.google/magika/), `cargo install --locked magika-cli`, or `pipx install magika`

Both backends are optional system tools (not Ruby gems). Be sure to install Magika in CI / production if you enable `:magika`.

If you want some inspiration about how to add `imagemagick`, `libvips`, `ffmpeg`, `poppler` or `magika` to your docker image, you can check how we do it for the gem CI (https://github.com/igorkasyanchuk/active_storage_validations/blob/master/.github/workflows/main.yml)

### Configuration

Optional global settings can go in an initializer. Example template:

```ruby
# config/initializers/active_storage_validations.rb
ActiveStorageValidations.configure do |config|
  # Infer HTML accept= on file_field from content_type validators (default: true)
  # config.infer_file_field_accept = false

  # Max time for external analyzer commands: ffprobe, pdfinfo, file, magika, ImageMagick identify, libvips
  # (default: 10.seconds; set to nil to disable)
  # config.command_timeout = 10.seconds
end

# Optional: monitor analyzer timeouts
# ActiveSupport::Notifications.subscribe("timeout.active_storage_validations") do |*args|
#   event = ActiveSupport::Notifications::Event.new(*args)
#   Rails.logger.warn("[ASV] command timeout: #{event.payload}")
# end
```

`command_timeout` bounds metadata analysis used by `dimension`, `aspect_ratio`, `duration`, `pages`, `processable_file`, and `content_type` (with `spoofing_protection`). When a command times out, analysis fails closed and the validator adds its usual error (`file_not_processable` / `media_metadata_missing` / content-type errors) — there is no separate timeout error message.

The 10s default is enough for typical uploads. Raise it (or set `nil`) if you analyze very large videos/PDFs, especially on slow or network storage — otherwise those files can start failing validation after upgrade. See [upgrade to 4.x](docs/upgrade_to_4.md#analyzer-command-timeout).

Per-validator override (applies to the analysis triggered by that validator; the first analysis for a blob is cached):

```ruby
validates :video, duration: { less_than: 5.minutes, timeout: 30.seconds }
```

Notes:
- Setting `command_timeout` (or per-validator `timeout:`) to `nil` disables the deadline
- ImageMagick analysis runs `identify` through the same killable command runner (MiniMagick is only used to build the argv)
- For libvips, a timeout may not immediately free the Ruby thread stuck in FFI/C; the validation still fails closed and emits `timeout.active_storage_validations`

## Validators

**List of validators:**
- [Attached](#attached): validates if file(s) attached
- [Limit](#limit): validates number of uploaded files
- [Content type](#content-type): validates file content type
- [Size](#size): validates file size
- [Total size](#total-size): validates total file size for several files
- [Dimension](#dimension): validates image / video dimensions
- [Duration](#duration): validates video / audio duration
- [Aspect ratio](#aspect-ratio): validates image / video aspect ratio
- [Processable file](#processable-file): validates if a file can be processed
- [Pages](#pages): validates pdf number of pages
<br>
<br>

**Proc usage**<br>
Every validator can use procs instead of values in all the validator examples:
```ruby
class User < ApplicationRecord
  has_many_attached :files

  validates :files, limit: { max: -> (record) { record.admin? ? 100 : 10 } }
end
```

**Performance optimization**<br>
Some validators rely on an expensive operation (metadata analysis and content type analysis). To mitigate the performance cost, the gem leverages the `ActiveStorage::Blob.metadata` method to store retrieved metadata. Therefore, once the file has been analyzed by our gem, the expensive analysis operation will not be triggered again for new validations.

As stated in the Rails documentation: "Blobs are intended to be immutable in so far as their reference to a specific file goes". We based our performance optimization on the same assumption, so if you do not follow it, the gem will not work as expected.

---

### Attached

Validates if the attachment is present.

#### Options

The `attached` validator has no options.

#### Examples

Use it like this:
```ruby
class User < ApplicationRecord
  has_one_attached :avatar

  validates :avatar, attached: true # ensures that avatar has an attached file
end
```

#### Error messages (I18n)

```yml
en:
  errors:
    messages:
      blank: "can't be blank"
```

The error message for this validator relies on Rails own `blank` error message.

---

### Limit

Validates the number of uploaded files.

#### Options

The `limit` validator has 2 possible options:
- `min`: defines the minimum allowed number of files
- `max`: defines the maximum allowed number of files

#### Examples

Use it like this:
```ruby
class User < ApplicationRecord
  has_many_attached :certificates

  validates :certificates, limit: { min: 1, max: 10 } # restricts the number of files to between 1 and 10
end
```

#### Error messages (I18n)

```yml
en:
  errors:
    messages:
      limit_out_of_range:
        zero: "no files attached (must have between %{min} and %{max} files)"
        one: "only 1 file attached (must have between %{min} and %{max} files)"
        other: "total number of files must be between %{min} and %{max} files (there are %{count} files attached)"
      limit_min_not_reached:
        zero: "no files attached (must have at least %{min} files)"
        one: "only 1 file attached (must have at least %{min} files)"
        other: "%{count} files attached (must have at least %{min} files)"
      limit_max_exceeded:
        zero: "no files attached (maximum is %{max} files)"
        one: "too many files attached (maximum is %{max} files, got %{count})"
        other: "too many files attached (maximum is %{max} files, got %{count})"
```

The `limit` validator error messages expose 3 values that you can use:
- `min` containing the minimum allowed number of files (e.g. `1`)
- `max` containing the maximum allowed number of files (e.g. `10`)
- `count` containing the current number of files (e.g. `5`)

---

### Content type

Validates if the attachment has an allowed content type.

#### Options

The `content_type` validator has several possible options:
- `with`: defines the allowed content type (string, symbol or regex)
- `in`: defines the allowed content types (array of strings or symbols)
- `spoofing_protection`: enables content type spoofing protection (`false` by default). Allowed values: `true` / `:file` (UNIX `file` CLI), `:magika` (Google Magika CLI)
- `timeout`: overrides the global analyzer [command timeout](#configuration) when spoofing protection runs `file` or `magika`

As mentioned above, this validator can define content types in several ways:
- String: `image/png` or `png`
- Symbol: `:png`
- Regex: `/\Avideo\/.*\z/`

#### Examples

Use it like this:
```ruby
class User < ApplicationRecord
  has_one_attached :avatar

  validates :avatar, content_type: 'image/png' # only allows PNG images
  validates :avatar, content_type: :png # only allows PNG images, same as { with: :png }
  validates :avatar, content_type: /\Avideo\/.*\z/ # only allows video files
  validates :avatar, content_type: ['image/png', 'image/jpeg'] # only allows PNG and JPEG images
  validates :avatar, content_type: { in: [:png, :jpeg], spoofing_protection: true } # UNIX `file` backend (same as :file)
  validates :avatar, content_type: { in: [:png, :jpeg], spoofing_protection: :magika } # Google Magika CLI backend
  # Stronger protection for media/PDF: sniff + parse
  validates :avatar, content_type: { in: [:png, :jpeg], spoofing_protection: true }, processable_file: true
end
```

#### HTML `accept` attribute (FormBuilder)

When using Rails' `FormBuilder#file_field`, the gem automatically sets the HTML [`accept`](https://developer.mozilla.org/en-US/docs/Web/HTML/Attributes/accept) attribute from your `content_type` validators. This improves UX by filtering selectable files in the browser dialog. It is only a frontend hint: a malicious user can still submit disallowed types, so keep the backend validation.

```ruby
class User < ApplicationRecord
  has_one_attached :avatar

  validates :avatar, content_type: ['image/png', 'image/jpeg']
end
```

```erb
<%= form_with model: @user do |f| %>
  <%= f.file_field :avatar %>
  <%# => <input type="file" accept="image/png,image/jpeg" ...> %>
<% end %>
```

Explicit `accept` values are never overridden. You can also disable inference:

```erb
<%# Per field %>
<%= f.file_field :avatar, infer_accept: false %>

<%# Or set a custom accept value %>
<%= f.file_field :avatar, accept: "image/*" %>
```

```ruby
# Globally — see [Configuration](#configuration) for a full initializer template
ActiveStorageValidations.infer_file_field_accept = false
# or:
# ActiveStorageValidations.configure { |config| config.infer_file_field_accept = false }
```

Notes:
- Only broad MIME-type regexes of the form `/\Aimage\/.*\z/` (or `video` / `audio` / etc.) are inferred, as `image/*`
- Other regexes (e.g. `/\Aimage\/(png|gif)\z/`) and Proc / dynamic `content_type` options are skipped, since they cannot be reliably represented in `accept`
- Conditional validators (`if:` / `unless:`) are not evaluated: their content types are always included in `accept`, even when the condition would skip the validator for that record. Backend validation is unchanged; use `infer_accept: false` (or a custom `accept:`) if the picker must match the active conditions

#### Content type shorthands

If you choose to use a content_type 'shorthand' (like `png`), note that it will be converted to a full content type using `Marcel::MimeType.for` under the hood. Therefore, you should check if the content_type is registered by [`Marcel::EXTENSIONS`](https://github.com/rails/marcel/blob/main/lib/marcel/tables.rb). If it's not, you can register it by adding the following code to your `config/initializers/mime_types.rb` file:

```ruby
Marcel::MimeType.extend "application/ino", extensions: %w(ino), parents: "text/plain" # Registering arduino INO files
```

Be sure to at least include one the `extensions`, `parents` or `magic` option, otherwise the content type will not be registered.

#### Content type spoofing protection

By default, the gem does not prevent content type spoofing. Enable it with `spoofing_protection`:

```ruby
validates :avatar, content_type: { in: [:png, :jpeg], spoofing_protection: true }     # => :file (UNIX file CLI)
validates :avatar, content_type: { in: [:png, :jpeg], spoofing_protection: :file }    # explicit
validates :avatar, content_type: { in: [:png, :jpeg], spoofing_protection: :magika }  # Google Magika CLI
```

Override binary paths with `ActiveStorage.paths[:file]` / `ActiveStorage.paths[:magika]` if needed.

<details>
<summary>
What is content type spoofing?
</summary>

File content type spoofing happens when an ill-intentioned user uploads a file which hides its true content type by faking its extension and its declared content type value. For example, a user may try to upload a `.exe` file (application/x-msdownload content type) dissimulated as a `.jpg` file (image/jpeg content type).
</details>

<details>
<summary>
How do we prevent it?
</summary>

Spoofing protection compares the declared Active Storage content type to a type detected by a sniffer CLI, then uses `Marcel` parent types so near-matches still pass:

- `:file` (default) — UNIX `file` / libmagic, mostly magic bytes / headers. Zero extra install on most UNIX systems.
- `:magika` — [Google Magika](https://github.com/google/magika) CLI (ML sniffer; samples begin/middle/end of the file). Generally more accurate than `file`, especially on textual / ambiguous formats (Google reports ~99% F1 vs ~88% for `file --mime` on overlapping types). Prefer `:magika` when you can install the CLI.

Neither backend fully parses the file. They do **not** load the whole file into RAM. For already-persisted blobs (e.g. remote storage), the analyzer still downloads the blob to a local tempfile before sniffing. That download is streamed in chunks to disk, but it can still be costly for very large files. Local path uploads are analyzed in place.

Detected types are cached on the blob as `asv_content_type` + `asv_content_type_backend`. Switching backend re-analyzes. Legacy blobs that only have `asv_content_type` (no backend key) are treated as `:file` and keep using the cache — they are not re-analyzed.

Sniffers will not always return the exact same MIME as Active Storage (AS uses first ~4kb + filename + extension). Close parent types are accepted via `Marcel::TYPE_PARENTS` (e.g. `video/x-ms-wmv` vs `video/x-ms-asf`).

For stronger protection on images / video / audio / PDF, combine sniffing with parse validation:

```ruby
validates :avatar, content_type: { in: [:png, :jpeg], spoofing_protection: true }, processable_file: true
```
</details>

<details>
<summary>
Edge cases
</summary>

The difficulty to accurately predict a mime type may generate false positives, if so there are several solutions available:
- Try the other sniffer backend (`:file` vs `:magika`)
- For media/PDF that sniffers misidentify but that open correctly, add `processable_file: true`
- If the ActiveStorage blob content type is closely related to the detected content type, enhance `Marcel::TYPE_PARENTS` mapping using `Marcel::MimeType.extend "application/x-rar-compressed", parents: %(application/x-rar)` in the `config/initializers/mime_types.rb` file. (Please drop an issue so we can add it to the gem for everyone!)
- If needed, disable spoofing protection in the validator, and please drop us an issue so we can fix it for everyone!
</details>


#### Error messages (I18n)

```yml
en:
  errors:
    messages:
      content_type_invalid:
        one: "has an invalid content type (authorized content type is %{authorized_human_content_types})"
        other: "has an invalid content type (authorized content types are %{authorized_human_content_types})"
      content_type_spoofed:
        one: "has a content type that is not equivalent to the one that is detected through its content (authorized content type is %{authorized_human_content_types})"
        other: "has a content type that is not equivalent to the one that is detected through its content (authorized content types are %{authorized_human_content_types})"
```

The `content_type` validator error messages expose 7 values that you can use:
- `content_type` containing the content type of the sent file (e.g. `image/png`)
- `human_content_type` containing a more user-friendly version of the sent file content type (e.g. 'TXT' for 'text/plain')
- `detected_content_type` containing the detected content type of the sent file using `spoofing_protection` option (e.g. `image/png`)
- `detected_human_content_type` containing a more user-friendly version of the sent file detected content type using `spoofing_protection` option (e.g. 'TXT' for 'text/plain')
- `authorized_human_content_types` containing the list of authorized content types (e.g. 'PNG, JPEG' for `['image/png', 'image/jpeg']`)
- `count` containing the number of authorized content types (e.g. `2`)
- `filename` containing the filename

---

### Size

Validates each attached file size.

#### Options

The `size` validator has 5 possible options:
- `less_than`: defines the strict maximum allowed file size
- `less_than_or_equal_to`: defines the maximum allowed file size
- `greater_than`: defines the strict minimum allowed file size
- `greater_than_or_equal_to`: defines the minimum allowed file size
- `between`: defines the allowed file size range
- `equal_to`: defines the allowed file size

#### Examples

Use it like this:
```ruby
class User < ApplicationRecord
  has_one_attached :avatar

  validates :avatar, size: { less_than: 2.megabytes } # restricts the file size to < 2MB
  validates :avatar, size: { less_than_or_equal_to: 2.megabytes } # restricts the file size to <= 2MB
  validates :avatar, size: { greater_than: 1.kilobyte } # restricts the file size to > 1KB
  validates :avatar, size: { greater_than_or_equal_to: 1.kilobyte } # restricts the file size to >= 1KB
  validates :avatar, size: { between: 1.kilobyte..2.megabytes } # restricts the file size to between 1KB and 2MB
  validates :avatar, size: { equal_to: 1.megabyte } # restricts the file size to exactly 1MB
end
```

#### Best practices

It is always a good practice to limit the maximum file size to a reasonable value (like 2MB for avatar images). This helps prevent server storage issues, reduces upload/download times, and ensures better performance. Large files can consume excessive bandwidth and storage space, potentially impacting both server resources and user experience.
Plus, not setting a size limit inside your Rails app might lead into your server throwing a `413 Content Too Large` error, which is not as nice as a Rails validation error.

#### Error messages (I18n)

```yml
en:
  errors:
    messages:
      file_size_not_less_than: "file size must be less than %{max} (current size is %{file_size})"
      file_size_not_less_than_or_equal_to: "file size must be less than or equal to %{max} (current size is %{file_size})"
      file_size_not_greater_than: "file size must be greater than %{min} (current size is %{file_size})"
      file_size_not_greater_than_or_equal_to: "file size must be greater than or equal to %{min} (current size is %{file_size})"
      file_size_not_between: "file size must be between %{min} and %{max} (current size is %{file_size})"
      file_size_not_equal_to: "file size must be equal to %{exact} (current size is %{file_size})"
```

The `size` validator error messages expose 4 values that you can use:
- `file_size` containing the current file size (e.g. `1.5MB`)
- `min` containing the minimum allowed file size (e.g. `1KB`)
- `exact` containing the allowed file size (e.g. `1MB`)
- `max` containing the maximum allowed file size (e.g. `2MB`)
- `filename` containing the current file name

---

### Total size

Validates the total file size for several files.

#### Options

The `total_size` validator has 5 possible options:
- `less_than`: defines the strict maximum allowed total file size
- `less_than_or_equal_to`: defines the maximum allowed total file size
- `greater_than`: defines the strict minimum allowed total file size
- `greater_than_or_equal_to`: defines the minimum allowed total file size
- `between`: defines the allowed total file size range
- `equal_to`: defines the allowed total file size

#### Examples

Use it like this:
```ruby
class User < ApplicationRecord
  has_many_attached :certificates

  validates :certificates, total_size: { less_than: 10.megabytes } # restricts the total size to < 10MB
  validates :certificates, total_size: { less_than_or_equal_to: 10.megabytes } # restricts the total size to <= 10MB
  validates :certificates, total_size: { greater_than: 1.kilobyte } # restricts the total size to > 1KB
  validates :certificates, total_size: { greater_than_or_equal_to: 1.kilobyte } # restricts the total size to >= 1KB
  validates :certificates, total_size: { between: 1.kilobyte..10.megabytes } # restricts the total size to between 1KB and 10MB
  validates :certificates, total_size: { equal_to: 1.megabyte } # restricts the total file size to exactly 1MB
end
```

#### Error messages (I18n)

```yml
en:
  errors:
    messages:
      total_file_size_not_less_than: "total file size must be less than %{max} (current size is %{total_file_size})"
      total_file_size_not_less_than_or_equal_to: "total file size must be less than or equal to %{max} (current size is %{total_file_size})"
      total_file_size_not_greater_than: "total file size must be greater than %{min} (current size is %{total_file_size})"
      total_file_size_not_greater_than_or_equal_to: "total file size must be greater than or equal to %{min} (current size is %{total_file_size})"
      total_file_size_not_between: "total file size must be between %{min} and %{max} (current size is %{total_file_size})"
      total_file_size_not_equal_to: "total file size must be equal to %{exact} (current size is %{total_file_size})"
```

The `total_size` validator error messages expose 4 values that you can use:
- `total_file_size` containing the current total file size (e.g. `1.5MB`)
- `min` containing the minimum allowed total file size (e.g. `1KB`)
- `exact` containing the allowed total file size (e.g. `1MB`)
- `max` containing the maximum allowed total file size (e.g. `2MB`)

---

### Dimension

Validates the dimension of the attached image / video files.
It can also be used for pdf files, but it will only analyze the pdf first page, and will assume a DPI of 72.
(be sure to have the right dependencies installed as mentioned in [installation](#installation))

#### Options

The `dimension` validator has several possible options:
- `width`: defines the allowed width (integer)
  - `min`: defines the minimum allowed width (integer)
  - `max`: defines the maximum allowed width (integer)
  - `in`: defines the allowed width range (range)
- `height`: defines the allowed height (integer)
  - `min`: defines the minimum allowed height (integer)
  - `max`: defines the maximum allowed height (integer)
  - `in`: defines the allowed height range (range)
- `min`: defines the minimum allowed width and height (range)
- `max`: defines the maximum allowed width and height (range)
- `timeout`: overrides the global analyzer [command timeout](#configuration) for this validation

#### Examples

Use it like this:
```ruby
class User < ApplicationRecord
  has_one_attached :avatar

  validates :avatar, dimension: { width: 100 } # restricts the width to 100 pixels
  validates :avatar, dimension: { width: { min: 80, max: 100 } } # restricts the width to between 80 and 100 pixels
  validates :avatar, dimension: { width: { in: 80..100 } } # restricts the width to between 80 and 100 pixels
  validates :avatar, dimension: { height: 100 } # restricts the height to 100 pixels
  validates :avatar, dimension: { height: { min: 600, max: 1800 } } # restricts the height to between 600 and 1800 pixels
  validates :avatar, dimension: { height: { in: 600..1800 } } # restricts the height to between 600 and 1800 pixels
  validates :avatar, dimension: { min: 80..600, max: 100..1800 } # restricts the width to between 80 and 100 pixels, and the height to between 600 and 1800 pixels
end
```

#### Error messages (I18n)

```yml
en:
  errors:
    messages:
      dimension_min_not_included_in: "must be greater than or equal to %{width} x %{height} pixels"
      dimension_max_not_included_in: "must be less than or equal to %{width} x %{height} pixels"
      dimension_width_not_included_in: "width is not included between %{min} and %{max} pixels"
      dimension_height_not_included_in: "height is not included between %{min} and %{max} pixels"
      dimension_width_not_greater_than_or_equal_to: "width must be greater than or equal to %{length} pixels"
      dimension_height_not_greater_than_or_equal_to: "height must be greater than or equal to %{length} pixels"
      dimension_width_not_less_than_or_equal_to: "width must be less than or equal to %{length} pixels"
      dimension_height_not_less_than_or_equal_to: "height must be less than or equal to %{length} pixels"
      dimension_width_not_equal_to: "width must be equal to %{length} pixels"
      dimension_height_not_equal_to: "height must be equal to %{length} pixels"
      media_metadata_missing: "is not a valid media file"
```

The `dimension` validator error messages expose 6 values that you can use:
- `min` containing the minimum width or height allowed
- `max` containing the maximum width or height allowed
- `width` containing the minimum or maximum width allowed
- `height` containing the minimum or maximum width allowed
- `length` containing the exact width or height allowed
- `filename` containing the current filename in error

---

### Duration

Validates the duration of the attached audio / video files.
(be sure to have the right dependencies installed as mentioned in [installation](#installation))

#### Options

The `duration` validator has several possible options:
- `less_than`: defines the strict maximum allowed file duration
- `less_than_or_equal_to`: defines the maximum allowed file duration
- `greater_than`: defines the strict minimum allowed file duration
- `greater_than_or_equal_to`: defines the minimum allowed file duration
- `between`: defines the allowed file duration range
- `equal_to`: defines the allowed duration
- `timeout`: overrides the global analyzer [command timeout](#configuration) for this validation

#### Examples

Use it like this:
```ruby
class User < ApplicationRecord
  has_one_attached :intro_song

  validates :intro_song, duration: { less_than: 2.minutes } # restricts the file duration to < 2 minutes
  validates :intro_song, duration: { less_than_or_equal_to: 2.minutes } # restricts the file duration to <= 2 minutes
  validates :intro_song, duration: { greater_than: 1.second } # restricts the file duration to > 1 second
  validates :intro_song, duration: { greater_than_or_equal_to: 1.second } # restricts the file duration to >= 1 second
  validates :intro_song, duration: { between: 1.second..2.minutes } # restricts the file duration to between 1 second and 2 minutes
  validates :intro_song, duration: { equal_to: 1.minute } # restricts the duration to exactly 1 minute
  validates :intro_song, duration: { less_than: 5.minutes, timeout: 5.seconds } # custom analyzer timeout
end
```

#### Error messages (I18n)

```yml
en:
  errors:
    messages:
      duration_not_less_than: "duration must be less than %{max} (current duration is %{duration})"
      duration_not_less_than_or_equal_to: "duration must be less than or equal to %{max} (current duration is %{duration})"
      duration_not_greater_than: "duration must be greater than %{min} (current duration is %{duration})"
      duration_not_greater_than_or_equal_to: "duration must be greater than or equal to %{min} (current duration is %{duration})"
      duration_not_between: "duration must be between %{min} and %{max} (current duration is %{duration})"
      duration_not_equal_to: "duration must be equal to %{exact} (current duration is %{duration})"
```

The `duration` validator error messages expose 4 values that you can use:
- `duration` containing the current duration size (e.g. `2 minutes`)
- `min` containing the minimum allowed duration size (e.g. `1 second`)
- `exact` containing the allowed duration (e.g. `3 seconds`)
- `max` containing the maximum allowed duration size (e.g. `2 minutes`)
- `filename` containing the current file name

---

### Aspect ratio

Validates the aspect ratio of the attached image / video files.
It can also be used for pdf files, but it will only analyze the pdf first page.
(be sure to have the right dependencies installed as mentioned in [installation](#installation))

#### Options

The `aspect_ratio` validator has several options:
- `with`: defines the allowed aspect ratio (e.g. `:is_16/9`)
- `in`: defines the allowed aspect ratios (e.g. `%i[square landscape]`)
- `timeout`: overrides the global analyzer [command timeout](#configuration) for this validation

This validator can define aspect ratios in several ways:
- Symbols:
  - prebuilt aspect ratios: `:square`, `:portrait`, `:landscape`
  - custom aspect ratios (it must be of type `is_xx_yy`): `:is_16_9`, `:is_4_3`, etc.

#### Examples

Use it like this:
```ruby
class User < ApplicationRecord
  has_one_attached :avatar

  validates :avatar, aspect_ratio: :square # restricts the aspect ratio to 1:1
  validates :avatar, aspect_ratio: :portrait # restricts the aspect ratio to x:y where y > x
  validates :avatar, aspect_ratio: :landscape # restricts the aspect ratio to x:y where x > y
  validates :avatar, aspect_ratio: :is_16_9 # restricts the aspect ratio to 16:9
  validates :avatar, aspect_ratio: %i[square is_16_9] # restricts the aspect ratio to 1:1 and 16:9
end
```

#### Error messages (I18n)

```yml
en:
  errors:
    messages:
      aspect_ratio_not_square: "must be square (current file is %{width}x%{height}px)"
      aspect_ratio_not_portrait: "must be portrait (current file is %{width}x%{height}px)"
      aspect_ratio_not_landscape: "must be landscape (current file is %{width}x%{height}px)"
      aspect_ratio_not_x_y: "must be %{authorized_aspect_ratios} (current file is %{width}x%{height}px)"
      aspect_ratio_invalid: "has an invalid aspect ratio (valid aspect ratios are %{authorized_aspect_ratios})"
      media_metadata_missing: "is not a valid media file"
```

The `aspect_ratio` validator error messages expose 4 values that you can use:
- `authorized_aspect_ratios` containing the authorized aspect ratios
- `width` containing the current width of the image/video
- `height` containing the current height of the image/video
- `filename` containing the current filename in error

---

### Processable file

Validates if the attached files can be processed by MiniMagick or Vips (image), ffmpeg (video/audio) or poppler (pdf).
(be sure to have the right dependencies installed as mentioned in [installation](#installation))

#### Options

The `processable_file` validator supports:
- `timeout`: overrides the global analyzer [command timeout](#configuration) for this validation

#### Examples

Use it like this:
```ruby
class User < ApplicationRecord
  has_one_attached :avatar

  validates :avatar, processable_file: true # ensures that the file is processable by MiniMagick or Vips (image) or ffmpeg (video/audio)
  validates :avatar, processable_file: { timeout: 5.seconds }
end
```

#### Error messages (I18n)

```yml
en:
  errors:
    messages:
      file_not_processable: "is not identified as a valid media file"
```

The `processable_file` validator error messages expose 1 value that you can use:
- `filename` containing the current filename in error

---

### Pages

Validates each attached pdf file number of pages.
(be sure to have the right dependencies installed as mentioned in [installation](#installation))

#### Options

The `pages` validator has several possible options:
- `less_than`: defines the strict maximum allowed number of pages
- `less_than_or_equal_to`: defines the maximum allowed number of pages
- `greater_than`: defines the strict minimum allowed number of pages
- `greater_than_or_equal_to`: defines the minimum allowed number of pages
- `between`: defines the allowed number of pages range
- `equal_to`: defines the allowed number of pages
- `timeout`: overrides the global analyzer [command timeout](#configuration) for this validation

#### Examples

Use it like this:
```ruby
class User < ApplicationRecord
  has_one_attached :contract

  validates :contract, pages: { less_than: 2 } # restricts the number of pages to < 2
  validates :contract, pages: { less_than_or_equal_to: 2 } # restricts the number of pages to <= 2
  validates :contract, pages: { greater_than: 1 } # restricts the number of pages to > 1
  validates :contract, pages: { greater_than_or_equal_to: 1 } # restricts the number of pages to >= 1
  validates :contract, pages: { between: 1..2 } # restricts the number of pages to between 1 and 2
  validates :contract, pages: { equal_to: 1 } # restricts the number of pages to exactly 1
end
```

#### Error messages (I18n)

```yml
en:
  errors:
    messages:
      pages_not_less_than: "page count must be less than %{max} (current page count is %{pages})"
      pages_not_less_than_or_equal_to: "page count must be less than or equal to %{max} (current page count is %{pages})"
      pages_not_greater_than: "page count must be greater than %{min} (current page count is %{pages})"
      pages_not_greater_than_or_equal_to: "page count must be greater than or equal to %{min} (current page count is %{pages})"
      pages_not_between: "page count must be between %{min} and %{max} (current page count is %{pages})"
      pages_not_equal_to: "page count must be equal to %{exact} (current page count is %{pages})"
```

The `pages` validator error messages expose 5 values that you can use:
- `pages` containing the current file number of pages (e.g. `7`)
- `min` containing the minimum allowed number of pages (e.g. `1`)
- `exact` containing the allowed number of pages (e.g. `3`)
- `max` containing the maximum allowed number of pages (e.g. `5`)
- `filename` containing the current file name

---

## Upgrading

- [Upgrading to 2.x](docs/upgrade_to_2.md)
- [Upgrading to 3.x](docs/upgrade_to_3.md)
- [Upgrading to 4.x](docs/upgrade_to_4.md)

## Internationalization (I18n)

Active Storage Validations uses I18n for error messages. The error messages are automatically loaded in your Rails app if your language translations are present in the gem.

Translation files are available [here](https://github.com/igorkasyanchuk/active_storage_validations/tree/master/config/locales). We currently have translations for `da`, `de`, `en`, `en-GB`, `es`, `fr`, `it`, `ja`, `nl`, `pl`, `pt-BR`, `ru`, `sv`, `tr`, `uk`, `vi` and `zh-CN`. Feel free to drop a PR to add your language ✌️.

If you wish to customize the error messages, just copy, paste and update the translation files into your application locales.

## Test matchers

The gem also provides RSpec-compatible and Minitest-compatible matchers for testing the validators.

### RSpec

#### Setup
In `spec_helper.rb`, you'll need to require the matchers:

```ruby
require 'active_storage_validations/matchers'
```

And include the module:

```ruby
RSpec.configure do |config|
  config.include ActiveStorageValidations::Matchers
end
```

#### Matchers
Matcher methods available:

```ruby
describe User do
  # aspect_ratio:
  # #allowing, #rejecting
  it { is_expected.to validate_aspect_ratio_of(:avatar).allowing(:square, :portrait) } # possible to use an Array or *splatted array
  it { is_expected.to validate_aspect_ratio_of(:avatar).rejecting(:square, :landscape) } # possible to use an Array or *splatted array

  # attached
  it { is_expected.to validate_attached_of(:avatar) }

  # processable_file
  it { is_expected.to validate_processable_file_of(:avatar) }

  # limit
  # #min, #max
  it { is_expected.to validate_limits_of(:avatar).min(1) }
  it { is_expected.to validate_limits_of(:avatar).max(5) }

  # content_type:
  # #allowing, #rejecting
  it { is_expected.to validate_content_type_of(:avatar).allowing('image/png', 'image/gif') } # possible to use an Array or *splatted array
  it { is_expected.to validate_content_type_of(:avatar).rejecting('text/plain', 'text/xml') } # possible to use an Array or *splatted array
  it { is_expected.to validate_content_type_of(:avatar).allowing('image/png').spoofing_protection } # true / :file
  it { is_expected.to validate_content_type_of(:avatar).allowing('image/png').spoofing_protection(:magika) }

  # dimension:
  # #width, #height, #width_min, #height_min, #width_max, #height_max, #width_between, #height_between
  it { is_expected.to validate_dimensions_of(:avatar).width(250) }
  it { is_expected.to validate_dimensions_of(:avatar).height(200) }
  it { is_expected.to validate_dimensions_of(:avatar).width_min(200) }
  it { is_expected.to validate_dimensions_of(:avatar).height_min(100) }
  it { is_expected.to validate_dimensions_of(:avatar).width_max(500) }
  it { is_expected.to validate_dimensions_of(:avatar).height_max(300) }
  it { is_expected.to validate_dimensions_of(:avatar).width_between(200..500) }
  it { is_expected.to validate_dimensions_of(:avatar).height_between(100..300) }

  # size:
  # #less_than, #less_than_or_equal_to, #greater_than, #greater_than_or_equal_to, #between, #equal_to
  it { is_expected.to validate_size_of(:avatar).less_than(50.kilobytes) }
  it { is_expected.to validate_size_of(:avatar).less_than_or_equal_to(50.kilobytes) }
  it { is_expected.to validate_size_of(:avatar).greater_than(1.kilobyte) }
  it { is_expected.to validate_size_of(:avatar).greater_than_or_equal_to(1.kilobyte) }
  it { is_expected.to validate_size_of(:avatar).between(100..500.kilobytes) }
  it { is_expected.to validate_size_of(:avatar).equal_to(5.megabytes) }

  # total_size:
  # #less_than, #less_than_or_equal_to, #greater_than, #greater_than_or_equal_to, #between, #equal_to
  it { is_expected.to validate_total_size_of(:avatar).less_than(50.kilobytes) }
  it { is_expected.to validate_total_size_of(:avatar).less_than_or_equal_to(50.kilobytes) }
  it { is_expected.to validate_total_size_of(:avatar).greater_than(1.kilobyte) }
  it { is_expected.to validate_total_size_of(:avatar).greater_than_or_equal_to(1.kilobyte) }
  it { is_expected.to validate_total_size_of(:avatar).between(100..500.kilobytes) }
  it { is_expected.to validate_total_size_of(:avatar).equal_to(5.megabytes) }

  # duration:
  # #less_than, #less_than_or_equal_to, #greater_than, #greater_than_or_equal_to, #between, #equal_to
  it { is_expected.to validate_duration_of(:introduction).less_than(50.seconds) }
  it { is_expected.to validate_duration_of(:introduction).less_than_or_equal_to(50.seconds) }
  it { is_expected.to validate_duration_of(:introduction).greater_than(1.minute) }
  it { is_expected.to validate_duration_of(:introduction).greater_than_or_equal_to(1.minute) }
  it { is_expected.to validate_duration_of(:introduction).between(100..500.seconds) }
  it { is_expected.to validate_duration_of(:avatar).equal_to(5.minutes) }

  # pages:
  # #less_than, #less_than_or_equal_to, #greater_than, #greater_than_or_equal_to, #between, #equal_to
  it { is_expected.to validate_pages_of(:contract).less_than(50) }
  it { is_expected.to validate_pages_of(:contract).less_than_or_equal_to(50) }
  it { is_expected.to validate_pages_of(:contract).greater_than(5) }
  it { is_expected.to validate_pages_of(:contract).greater_than_or_equal_to(5) }
  it { is_expected.to validate_pages_of(:contract).between(100..500) }
  it { is_expected.to validate_pages_of(:contract).equal_to(5) }
end
```
(Note that matcher methods are chainable)

All matchers can currently be customized with these options:

```ruby
describe User do
  # :allow_blank
  it { is_expected.to validate_attached_of(:avatar).allow_blank }

  # :on
  it { is_expected.to validate_attached_of(:avatar).on(:update) }
  it { is_expected.to validate_attached_of(:avatar).on(%i[update custom]) }

  # :except_on (Rails >= 8.0)
  it { is_expected.to validate_attached_of(:avatar).except_on(:update) }
  it { is_expected.to validate_attached_of(:avatar).except_on(%i[update custom]) }

  # :message
  it { is_expected.to validate_dimensions_of(:avatar).width(250).with_message('Invalid dimensions.') }

  # :timeout (analyzer command timeout — metadata validators + content_type with spoofing)
  it { is_expected.to validate_duration_of(:video).less_than(5.minutes).timeout(30.seconds) }
  it { is_expected.to validate_processable_file_of(:avatar).timeout(5.seconds) }
end
```

### Minitest

#### Setup
To use the matchers, make sure you have the [shoulda-context](https://github.com/thoughtbot/shoulda-context) gem up and running.

You need to require the matchers:

```ruby
require 'active_storage_validations/matchers'
```

And extend the module:

```ruby
class ActiveSupport::TestCase
  extend ActiveStorageValidations::Matchers
end
```

#### Matchers
Then you can use the matchers with the syntax specified in the RSpec section, just use `should validate_method` instead of `it { is_expected_to validate_method }` as specified in the [shoulda-context](https://github.com/thoughtbot/shoulda-context) gem.


## Contributing

If you want to contribute to the project, you will have to fork the repository and create a new branch from the `master` branch. Then build your feature, or fix the issue, and create a pull request. Be sure to add tests for your changes.

AI coding agents: see [AGENTS.md](AGENTS.md) for architecture, test commands, and contribution patterns. Commit and PR titles follow [Conventional Commits](.cursor/rules/git.mdc).

Before submitting your pull request, run the tests to make sure everything works as expected.

To run the gem tests, launch the following commands in the root folder of gem repository:

* `BUNDLE_GEMFILE=gemfiles/rails_7_0_1.gemfile bundle exec rake spec` to run for Rails 7.0.1
* `BUNDLE_GEMFILE=gemfiles/rails_7_1.gemfile bundle exec rake spec` to run for Rails 7.1
* `BUNDLE_GEMFILE=gemfiles/rails_7_2.gemfile bundle exec rake spec` to run for Rails 7.2
* `BUNDLE_GEMFILE=gemfiles/rails_8_0.gemfile bundle exec rake spec` to run for Rails 8.0
* `BUNDLE_GEMFILE=gemfiles/rails_8_1.gemfile bundle exec rake spec` to run for Rails 8.1
* `BUNDLE_GEMFILE=gemfiles/rails_next.gemfile bundle exec rake spec` to run for Rails main

Snippet to run in console:

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

Tips:
- To focus examples, tag them with `:focus` (or use `fit` / `fdescribe`); RSpec is configured with `filter_run_when_matching :focus`
- To run a specific file: `bundle exec rspec spec/validators/size_validator_spec.rb`
- Image processor: CI runs both via `IMAGE_PROCESSOR=vips` / `IMAGE_PROCESSOR=mini_magick`. Locally, unset means validators use MiniMagick (ASV default) and both analyzer unit specs run; setting the env selects that processor for validators and excludes the other processor’s tagged examples (so they do not show as pending)

### Benchmarks

Optional wall-clock / ips suite for metadata validators (cold analysis vs cached `asv_*` hits) lives under [`benchmark/`](benchmark/). See [`benchmark/README.md`](benchmark/README.md) for setup, how to run, and how to refresh [`benchmark/BASELINE.md`](benchmark/BASELINE.md). CI runs the suite informationally (no fail-on-regression).


## Additional information

### Contributors (BIG THANK YOU!)

We have a long list of valued contributors. Check them all at:

https://github.com/igorkasyanchuk/active_storage_validations/graphs/contributors

### License

The gem is available as open source under the terms of the [MIT License](https://opensource.org/licenses/MIT).

<br>

[<img src="https://github.com/igorkasyanchuk/rails_time_travel/blob/main/docs/more_gems.png?raw=true"
/>](https://www.railsjazz.com/?utm_source=github&utm_medium=bottom&utm_campaign=active_storage_validations)

[!["Buy Me A Coffee"](https://github.com/igorkasyanchuk/get-smart/blob/main/docs/snapshot-bmc-button.png?raw=true)](https://buymeacoffee.com/igorkasyanchuk)
