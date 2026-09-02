# frozen_string_literal: true

source "https://rubygems.org"
git_source(:github) { |repo| "https://github.com/#{repo}.git" }

# Declare your gem's dependencies in active_storage_validations.gemspec.
# Bundler will treat runtime dependencies like base dependencies, and
# development dependencies will be added by default to the :development group.
gemspec

# Declare any dependencies that are still in development here instead of in
# your gemspec. These might include edge Rails or gems from your path or
# Git. Remember to move these dependencies to your gemspec before releasing
# your gem to rubygems.org.

# Local default Gemfile: used by `bundle exec rake spec` without BUNDLE_GEMFILE.
gem "rails", "8.1.3.1"
# gem "sqlite3", ">= 2.5"
# gem "nokogiri", ">= 1.18"

group :development, :test do
  # To use debugger:
  # gem "debug", "~> 1.10", ">= 1.10.0"

  # To test S3 services
  # gem "aws-sdk-s3", require: false

  # Linters
  gem "rubocop", "~> 1.90", require: false
  gem "rubocop-performance", "~> 1.27", require: false
  gem "rubocop-rails-omakase", "~> 1.1", require: false
  gem "rubocop-rspec", "~> 3.0", require: false
end

# Optional: performance suite under benchmark/
# Install with: bundle config set --local with benchmark && bundle install
# (or omit BUNDLE_WITHOUT=benchmark). See benchmark/README.md.
group :benchmark do
  gem "benchmark-ips"
  gem "vernier", require: false
end
