# Upgrading to 4.x

Version 4 updates the supported Rails and Ruby versions.

## Breaking changes

- Drop support for Rails 6.1.4 and 7.0.0 (we keep support for Rails >= 7.0.1)
- Drop support for Ruby 3.1 and 3.2 in the CI matrix, since the recommended version for Rails >= 7.0.1 is Ruby >= 3.3

Make sure your application runs on Rails >= 7.0.1 and Ruby >= 3.3 before upgrading.

## Other changes

- Add support for Ruby 4.0 in the CI matrix
