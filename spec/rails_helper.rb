# frozen_string_literal: true

return if defined?(ASV_RAILS_HELPER_LOADED)

ASV_RAILS_HELPER_LOADED = true

require "spec_helper"

ENV["RAILS_ENV"] = "test"

require "combustion"
Combustion.path = "test/dummy"
Combustion.initialize! :active_record, :active_storage, :active_job do
  config.active_storage.variant_processor = ENV["IMAGE_PROCESSOR"]&.to_sym

  # Uncomment this to test S3 services
  # require "aws-sdk-s3"
  # config.active_storage.service = :digitalocean

  config.active_job.queue_adapter = :inline

  # Active Storage enqueues PreviewImageJob on attach when system previewers
  # (poppler / ffmpeg) are present. That path requires the image_processing gem,
  # which this project does not use (analyzers call mini_magick / ruby-vips /
  # pdfinfo directly). Disable previewers so PDF/video saves do not fail in CI.
  config.active_storage.previewers = []
end

require "rspec/rails"

# Support files (file helpers, locale, mime types)
Dir[File.expand_path("support/**/*.rb", __dir__)].sort.each { |f| require f }

# Area-specific helpers
Dir[File.expand_path("{validators,matchers,analyzers}/support/**/*.rb", __dir__)].sort.each { |f| require f }

# Shared examples
Dir[File.expand_path("{validators,matchers,analyzers}/shared_examples/**/*.rb", __dir__)].sort.each { |f| require f }

RSpec.configure do |config|
  config.fixture_paths = [ File.expand_path("../test/fixtures", __dir__) ] if config.respond_to?(:fixture_paths=)
  config.use_transactional_fixtures = true
  config.infer_spec_type_from_file_location!
  config.filter_rails_from_backtrace!

  config.include ValidatorHelpers, file_path: %r{spec/validators}
  config.include MatcherHelpers, file_path: %r{spec/matchers}
  config.include AnalyzerHelpers, file_path: %r{spec/analyzers}

  config.after(:suite) do
    FileUtils.rm_rf(Rails.root.join("tmp/storage"))
  end
end

puts "Running specs with Rails v.#{Rails.version}"
