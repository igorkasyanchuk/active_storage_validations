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

# This Rails version will be the one used when running `bundle exec rake test` locally
# Uncomment the line then run `bundle install`
# gem "rails", "7.1.2"
# gem "sqlite3", "~> 1.7"
# gem "nokogiri", "~> 1.16", ">= 1.16.7"

group :development, :test do
  # To use debugger:
  # gem "debug", "~> 1.10", ">= 1.10.0"

  # Linters
  gem "rubocop", "~> 1.71", ">= 1.71.1", require: false
  gem "rubocop-performance", "~> 1.23", ">= 1.23.1", require: false
  gem "rubocop-rails-omakase", "~> 1.0", ">= 1.0.0", require: false
end
