# frozen_string_literal: true

# Measure gem load time (faker-style sanity check).
# Rails is preloaded because Engine/Railtie subclass Rails::Engine / Rails::Railtie.
#
#   bundle exec ruby benchmark/require.rb

require "bundler/setup"
require "benchmark"
require "rails"
require "active_record"
require "active_job"
require "active_storage"

ms = Benchmark.realtime do
  require "active_storage_validations"
end * 1000

puts "ruby: #{RUBY_DESCRIPTION}"
puts "rails: #{Rails.version} (preloaded; not included in timing)"
puts "took #{ms.round(3)}ms to load active_storage_validations"
