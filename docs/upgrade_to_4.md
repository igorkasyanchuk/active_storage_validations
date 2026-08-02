# Upgrading to 4.x

Version 4 updates the supported Rails and Ruby versions, and adds automatic HTML `accept` inference for file fields.

## Breaking changes

- Drop support for Rails 6.1.4 and 7.0.0 (we keep support for Rails >= 7.0.1)
- Drop support for Ruby < 3.3 (`required_ruby_version` is now `>= 3.3.0`)
- `FormBuilder#file_field` now automatically sets the HTML `accept` attribute from `content_type` validators

Make sure your application runs on Rails >= 7.0.1 and Ruby >= 3.3 before upgrading.

### File field `accept` attribute

After upgrading, calls such as `f.file_field :avatar` may start rendering an `accept` attribute when a `content_type` validator is defined on that attribute. This can change browser file-picker behavior and may break view tests that assert exact HTML.

To keep the previous behavior:

```ruby
# Globally (e.g. in config/initializers/active_storage_validations.rb)
ActiveStorageValidations.infer_file_field_accept = false
```

```erb
<%# Per field %>
<%= f.file_field :avatar, infer_accept: false %>
```

Explicit `accept:` values are never overridden.

## Other changes

- Add support for Ruby 4.0 in the CI matrix
