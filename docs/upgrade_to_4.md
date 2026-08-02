# Upgrading to 4.x

Version 4 updates the supported Rails and Ruby versions, adds automatic HTML `accept` inference for file fields, analyzer command timeouts, and matcher support for Rails `:except_on`.

## Breaking changes

- Drop support for Rails 6.1.4 and 7.0.0 (we keep support for Rails >= 7.0.1)
- Drop support for Ruby < 3.3 (`required_ruby_version` is now `>= 3.3.0`)
- `FormBuilder#file_field` now automatically sets the HTML `accept` attribute from `content_type` validators
- Analyzer commands default to a 10 second timeout (breaking only for apps whose metadata analysis can legitimately exceed 10s — see below)

Make sure your application runs on Rails >= 7.0.1 and Ruby >= 3.3 before upgrading.

### File field `accept` attribute

After upgrading, calls such as `f.file_field :avatar` may start rendering an `accept` attribute when a `content_type` validator is defined on that attribute. This can change browser file-picker behavior and may break view tests that assert exact HTML.

To keep the previous behavior:

```ruby
# Globally (see README Configuration for a full initializer template)
ActiveStorageValidations.infer_file_field_accept = false
```

```erb
<%# Per field %>
<%= f.file_field :avatar, infer_accept: false %>
```

Explicit `accept:` values are never overridden.

### Analyzer command timeout

Without a deadline, a single pathological or crafted upload can stall an analyzer binary (`ffprobe`, ImageMagick, …) indefinitely and tie up a request or background worker. A default timeout closes that hang/DoS class of failure while keeping normal uploads fast: analysis either finishes or fails closed with the validator’s existing error.

Metadata analysis (`ffprobe`, `pdfinfo`, `file`, ImageMagick `identify`, libvips) now defaults to a **10 second** command timeout (`ActiveStorageValidations.command_timeout`). Commands that previously could hang forever now fail closed after that deadline; validators then add their usual errors (`file_not_processable`, `media_metadata_missing`, etc.).

**Who is affected?** Most apps are not. Typical image / audio / short-video / PDF metadata extraction finishes in milliseconds to a couple of seconds. This is a breaking change only if legitimate uploads need more than 10s to analyze — for example:

- Very large videos analyzed with `duration` / `processable_file` (especially on slow disks or network-mounted / remote storage)
- Unusually large PDFs with `pages`
- Environments where analyzer binaries are cold-started or heavily CPU-contended

If you hit that case, raise or disable the limit:

```ruby
# config/initializers/active_storage_validations.rb
ActiveStorageValidations.configure do |config|
  config.command_timeout = 30.seconds # or nil to restore unbounded waits
end
```

Or only for the slow validator: `validates :video, duration: { less_than: 5.minutes, timeout: 30.seconds }`.

Subscribe to `timeout.active_storage_validations` after upgrading if you want to confirm whether any real uploads are timing out in production.

See the README [Configuration](../README.md#configuration) section for the full initializer template and Notifications monitoring example.

## Other changes

### Added

- `#except_on` matcher option to support Rails `:except_on` (available since Rails 8.0), e.g. `validate_attached_of(:avatar).except_on(:update)`
- Optional per-validator `timeout:` for analyzer commands, plus `timeout.active_storage_validations` instrumentation (timed-out analysis fails closed using existing validation errors)
- `#timeout` matcher option for metadata validators and `content_type`, e.g. `validate_duration_of(:video).less_than(5.minutes).timeout(30.seconds)`

### Fixed

- `dimension: { min:, max: }` when both top-level bounds are set together (previously the second bound overwrote the first)
- Proc options with arity 0 (e.g. `-> { 2.kilobytes..7.kilobytes }`) being called with the record argument

### Misc

- Add support for Ruby 4.0 in the CI matrix
- The gem’s own test suite migrated from Minitest to RSpec; consumer matcher APIs for RSpec and Minitest/shoulda are unchanged
